#!/usr/bin/env python3
"""Prepare, execute, and audit deterministic BDS Stage 6 actions."""

from __future__ import annotations

import argparse
import contextlib
import csv
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any, Iterable


WORKSPACE = Path(__file__).resolve().parents[2]
EXECUTION_ROOT = WORKSPACE / "tests" / "testdata" / "kimi_stage6_execution"
STATE_FILE = EXECUTION_ROOT / "state.json"
LOCK_FILE = EXECUTION_ROOT / ".execution.lock"
TASK_FILE = WORKSPACE / "tests" / "competitors" / "kimi_stage6_task.json"
CATALOG_FILE = WORKSPACE / "tests" / "tools" / "kimi_stage6_actions.json"
MATLAB_BIN = Path("/Applications/MATLAB_R2024b.app/bin/matlab")
ACTION_ID = "bds.stage6.verify_equivalence"
INITIAL_STATE = "EQUIVALENCE_GATE"
NEXT_STATE = "TIER1_RUNS_1_TO_20"
WORKFLOW_ID = "bds-stage6"
EXPECTED_PROBLEMS = {
    "FMINSRF2": 16,
    "FLETCHCR": 10,
    "GENHUMPS": 10,
    "COOLHANSLS": 9,
    "EXTROSNB": 10,
    "DIXON3DQ": 10,
    "HILBERTB": 10,
    "MSQRTALS": 25,
    "SBRYBND": 10,
}
EXPECTED_SIGMAS = {"0.1", "0.01"}
EXPECTED_ALGORITHMS = {"ds", "cbds"}


class ExecutionError(RuntimeError):
    """Raised when an execution gate or postcondition fails."""


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ExecutionError(f"Cannot read JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ExecutionError(f"Expected a JSON object in {path}.")
    return value


def atomic_write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(value, ensure_ascii=True, indent=2) + "\n"
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def canonical_json(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=True, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def plan_hash(plan: dict[str, Any]) -> str:
    unsigned = dict(plan)
    unsigned.pop("plan_sha256", None)
    return sha256_bytes(canonical_json(unsigned))


def validate_plan_hash(plan: dict[str, Any], approval: str | None = None) -> None:
    recorded = plan.get("plan_sha256")
    computed = plan_hash(plan)
    if not isinstance(recorded, str) or recorded != computed:
        raise ExecutionError("The execution plan has been modified after signing.")
    if approval is not None and approval != recorded:
        raise ExecutionError("The supplied approval hash does not match the plan.")


def path_label(path: Path) -> str:
    resolved = Path(os.path.abspath(path))
    try:
        return str(resolved.relative_to(WORKSPACE))
    except ValueError:
        return str(resolved)


def require_files(paths: Iterable[Path]) -> list[Path]:
    files = sorted(
        {Path(os.path.abspath(path)) for path in paths}, key=lambda item: str(item)
    )
    missing = [str(path) for path in files if not path.is_file() and not path.is_symlink()]
    if missing:
        raise ExecutionError(f"Required input files are missing: {missing}")
    return files


def stage3_data_files() -> list[Path]:
    root = WORKSPACE / "tests" / "testdata" / "ds_vs_cbds_high_noise_primary_20260712_165527"
    files = sorted(root.rglob("data_for_loading.mat"))
    if len(files) != 3:
        raise ExecutionError(
            f"Expected exactly three Stage 3 data files, found {len(files)}."
        )
    return files


def input_files() -> list[Path]:
    optiprofiler = Path(
        "/Users/lihaitian/local/optiprofiler/matlab/optiprofiler"
    )
    s2mpj = optiprofiler / "problem_libs" / "s2mpj"
    paths: list[Path] = [
        Path(__file__),
        WORKSPACE / "tests" / "run_stage6_trace_equivalence_gate.m",
        WORKSPACE / "tests" / "verify_trace_ds_cbds_baseline.m",
        WORKSPACE / "tests" / "competitors" / "trace_ds_cbds_baseline.m",
        WORKSPACE / "tests" / "competitors" / "accelerated_bds_options.m",
        TASK_FILE,
        CATALOG_FILE,
        WORKSPACE / "tests" / "testdata"
        / "ds_vs_cbds_high_noise_primary_20260712_165527"
        / "aggregate_manifest.mat",
        MATLAB_BIN,
        s2mpj / "s2mpj_load.m",
        s2mpj / "probinfo_matlab.mat",
        s2mpj / "src" / "s2mpjlib.m",
    ]
    paths.extend((WORKSPACE / "src" / "private").glob("*.m"))
    paths.extend((WORKSPACE / "tests" / "competitors" / "private").glob("*.m"))
    paths.extend((optiprofiler / "src").glob("*.m"))
    paths.extend(stage3_data_files())
    for problem in EXPECTED_PROBLEMS:
        paths.append(s2mpj / "src" / "matlab_problems" / f"{problem}.m")
    return require_files(paths)


def fingerprint_inputs() -> list[dict[str, Any]]:
    entries = []
    for path in input_files():
        if path.is_symlink():
            target = os.readlink(path)
            payload = target.encode("utf-8")
            entries.append({
                "path": path_label(path),
                "type": "symlink",
                "target": target,
                "bytes": len(payload),
                "sha256": sha256_bytes(payload),
            })
        else:
            stat = path.stat()
            entries.append({
                "path": path_label(path),
                "type": "file",
                "bytes": stat.st_size,
                "sha256": sha256_file(path),
            })
    return entries


def git_snapshot() -> dict[str, str]:
    commit = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=WORKSPACE, check=True,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout.strip()
    status = subprocess.run(
        ["git", "status", "--porcelain=v1", "-uall"], cwd=WORKSPACE,
        check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout
    return {
        "commit": commit,
        "status_sha256": sha256_bytes(status.encode("utf-8")),
    }


def initial_state() -> dict[str, Any]:
    task = read_json(TASK_FILE)
    if task.get("mode") != "workflow" or task.get("current_state") != INITIAL_STATE:
        raise ExecutionError(
            f"The Stage 6 task must start in {INITIAL_STATE}."
        )
    return {
        "schema_version": 1,
        "workflow_id": WORKFLOW_ID,
        "state": INITIAL_STATE,
        "pending_plan_sha256": None,
        "completed_actions": [],
        "last_attempt": None,
        "created_at": utc_now(),
        "updated_at": utc_now(),
    }


def load_or_create_state() -> dict[str, Any]:
    if not STATE_FILE.exists():
        state = initial_state()
        atomic_write_json(STATE_FILE, state)
        return state
    state = read_json(STATE_FILE)
    required = {
        "schema_version", "workflow_id", "state", "pending_plan_sha256",
        "completed_actions", "last_attempt", "created_at", "updated_at",
    }
    if set(state) != required:
        raise ExecutionError("The Stage 6 state file has an invalid schema.")
    if state["schema_version"] != 1 or state["workflow_id"] != WORKFLOW_ID:
        raise ExecutionError("The Stage 6 state identity is invalid.")
    if not isinstance(state["completed_actions"], list):
        raise ExecutionError("completed_actions must be a list.")
    return state


@contextlib.contextmanager
def execution_lock():
    EXECUTION_ROOT.mkdir(parents=True, exist_ok=True)
    with LOCK_FILE.open("a+", encoding="utf-8") as stream:
        try:
            fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise ExecutionError("Another Stage 6 executor process holds the lock.") from exc
        yield


def validate_catalog_action(state_name: str) -> dict[str, Any]:
    catalog = read_json(CATALOG_FILE)
    if catalog.get("execution_enabled") is not False:
        raise ExecutionError("The Kimi action catalog must remain advisory-only.")
    matches = [action for action in catalog.get("actions", []) if action.get("id") == ACTION_ID]
    if len(matches) != 1:
        raise ExecutionError(f"Action {ACTION_ID} is missing or duplicated.")
    action = matches[0]
    if action.get("allowed_from") != [INITIAL_STATE]:
        raise ExecutionError("The equivalence action source state changed.")
    if action.get("next_state") != NEXT_STATE:
        raise ExecutionError("The equivalence action next state changed.")
    if action.get("argument_keys") != []:
        raise ExecutionError("The equivalence action must not accept arguments.")
    if action.get("requires_codex_authorization") is not True:
        raise ExecutionError("The equivalence action must require Codex authorization.")
    if state_name not in action["allowed_from"]:
        raise ExecutionError(f"Action {ACTION_ID} is invalid from {state_name}.")
    return action


def validate_implemented_action(action_id: str) -> None:
    if action_id != ACTION_ID:
        raise ExecutionError(f"Action {action_id!r} is not implemented.")


def action_from_response(response_file: Path) -> tuple[str, dict[str, Any]]:
    response = read_json(response_file)
    task = read_json(TASK_FILE)
    if response.get("schema_version") != 2:
        raise ExecutionError("The Kimi response schema is invalid.")
    if response.get("task_id") != task.get("task_id"):
        raise ExecutionError("The Kimi response task ID does not match Stage 6.")
    if response.get("current_state") != task.get("current_state"):
        raise ExecutionError("The Kimi response state does not match the task.")
    requested = response.get("requested_action")
    if not isinstance(requested, dict) or set(requested) != {"id", "arguments"}:
        raise ExecutionError("The Kimi response has no valid requested action.")
    if requested["arguments"] != {}:
        raise ExecutionError("The equivalence action accepts no arguments.")
    return str(requested["id"]), {
        "kind": "validated_kimi_response",
        "response_file": path_label(response_file),
        "response_sha256": sha256_file(response_file),
    }


def select_action(args: argparse.Namespace) -> tuple[str, dict[str, Any]]:
    if args.response is not None:
        if args.action_id is not None or args.direct_user_authorization:
            raise ExecutionError("Use either --response or direct authorization, not both.")
        return action_from_response(args.response.resolve())
    if not args.direct_user_authorization or args.action_id is None:
        raise ExecutionError(
            "Direct selection requires --action-id and --direct-user-authorization."
        )
    return args.action_id, {
        "kind": "direct_user_authorization",
        "record": "Explicit user authorization in the controlling Codex session.",
    }


def matlab_quote(value: str) -> str:
    return value.replace("'", "''")


def matlab_argv(output_dir: Path) -> list[str]:
    expression = (
        f"cd('{matlab_quote(str(WORKSPACE))}'); "
        "addpath('tests'); "
        f"run_stage6_trace_equivalence_gate('{matlab_quote(str(output_dir))}');"
    )
    return [str(MATLAB_BIN), "-batch", expression]


def make_plan(action_source: dict[str, Any], state: dict[str, Any]) -> dict[str, Any]:
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    run_id = f"verify_equivalence_{stamp}"
    run_dir = EXECUTION_ROOT / "runs" / run_id
    output_dir = run_dir / "verification"
    plan: dict[str, Any] = {
        "schema_version": 1,
        "workflow_id": WORKFLOW_ID,
        "plan_id": run_id,
        "action_id": ACTION_ID,
        "action_source": action_source,
        "current_state": state["state"],
        "next_state_on_success": NEXT_STATE,
        "created_at": utc_now(),
        "workspace": str(WORKSPACE),
        "git": git_snapshot(),
        "input_fingerprints": fingerprint_inputs(),
        "execution": {
            "working_directory": str(WORKSPACE),
            "argv": matlab_argv(output_dir),
            "shell": False,
            "run_directory": path_label(run_dir),
            "output_directory": path_label(output_dir),
            "log_file": path_label(run_dir / "matlab.log"),
        },
        "expected": {
            "solver_runs": 180,
            "problems": EXPECTED_PROBLEMS,
            "noise_levels": [0.1, 0.01],
            "runs": [1, 2, 3, 4, 5],
            "algorithms": ["ds", "cbds"],
            "max_eval_factor": 200,
            "step_tolerance": 1e-6,
            "all_formal_exact": True,
            "all_trace_internal_exact": True,
            "all_stage3_exact": True,
        },
    }
    plan["plan_sha256"] = plan_hash(plan)
    return plan


def validate_plan_schema(plan: dict[str, Any]) -> None:
    required = {
        "schema_version", "workflow_id", "plan_id", "action_id", "action_source",
        "current_state", "next_state_on_success", "created_at", "workspace", "git",
        "input_fingerprints", "execution", "expected", "plan_sha256",
    }
    if set(plan) != required:
        raise ExecutionError("The execution plan has an invalid top-level schema.")
    if plan["schema_version"] != 1 or plan["workflow_id"] != WORKFLOW_ID:
        raise ExecutionError("The execution plan identity is invalid.")
    if plan["action_id"] != ACTION_ID:
        raise ExecutionError(f"Action {plan['action_id']!r} is not implemented.")
    if plan["current_state"] != INITIAL_STATE or plan["next_state_on_success"] != NEXT_STATE:
        raise ExecutionError("The execution plan state transition is invalid.")
    execution = plan["execution"]
    if not isinstance(execution, dict) or execution.get("shell") is not False:
        raise ExecutionError("The execution plan must use shell=false.")
    output_dir = resolve_execution_path(execution.get("output_directory"), "output_directory")
    expected_argv = matlab_argv(output_dir)
    if execution.get("argv") != expected_argv:
        raise ExecutionError("The execution argv is not the fixed MATLAB command.")


def resolve_execution_path(value: Any, field: str) -> Path:
    if not isinstance(value, str):
        raise ExecutionError(f"execution.{field} must be a string.")
    path = (WORKSPACE / value).resolve() if not Path(value).is_absolute() else Path(value).resolve()
    try:
        path.relative_to(EXECUTION_ROOT.resolve())
    except ValueError as exc:
        raise ExecutionError(f"execution.{field} escapes the execution root.") from exc
    return path


def verify_input_fingerprints(recorded: Any) -> None:
    current = fingerprint_inputs()
    if recorded != current:
        raise ExecutionError(
            "An execution input changed after plan approval; prepare a new plan."
        )


def prepare(args: argparse.Namespace) -> Path:
    with execution_lock():
        state = load_or_create_state()
        if state["state"] != INITIAL_STATE:
            raise ExecutionError(
                f"The workflow is in {state['state']}, not {INITIAL_STATE}."
            )
        if state["pending_plan_sha256"] is not None:
            raise ExecutionError(
                "A pending execution plan already exists; run or inspect it first."
            )
        selected_action, action_source = select_action(args)
        validate_implemented_action(selected_action)
        validate_catalog_action(state["state"])
        plan = make_plan(action_source, state)
        plan_file = EXECUTION_ROOT / "plans" / f"{plan['plan_id']}.json"
        if plan_file.exists():
            raise ExecutionError(f"Plan already exists: {plan_file}")
        atomic_write_json(plan_file, plan)
        state["pending_plan_sha256"] = plan["plan_sha256"]
        state["updated_at"] = utc_now()
        atomic_write_json(STATE_FILE, state)
        print(json.dumps({
            "status": "prepared",
            "plan_file": str(plan_file),
            "plan_sha256": plan["plan_sha256"],
            "action_id": ACTION_ID,
            "current_state": INITIAL_STATE,
            "next_state_on_success": NEXT_STATE,
            "argv": plan["execution"]["argv"],
            "expected_solver_runs": 180,
        }, ensure_ascii=True, indent=2))
        return plan_file


def normalize_sigma(value: str) -> str:
    number = float(value)
    if number == 0.1:
        return "0.1"
    if number == 0.01:
        return "0.01"
    return value


def audit_verification(output_dir: Path) -> dict[str, Any]:
    csv_file = output_dir / "stage6_trace_equivalence_verification.csv"
    mat_file = output_dir / "stage6_trace_equivalence_verification.mat"
    md_file = output_dir / "stage6_trace_equivalence_verification.md"
    for path in (csv_file, mat_file, md_file):
        if not path.is_file() or path.stat().st_size == 0:
            raise ExecutionError(f"Missing or empty verification artifact: {path}")
    with csv_file.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if len(rows) != 180:
        raise ExecutionError(f"Expected 180 verification rows, found {len(rows)}.")
    required_columns = {
        "problem", "n", "sigma", "run", "seed", "algorithm", "maxfun",
        "trace_func_count", "stage3_func_count", "formal_exitflag",
        "trace_exitflag", "formal_exact", "trace_internal_exact", "stage3_exact",
        "trace_returned_true", "stage3_returned_true",
    }
    if set(rows[0]) != required_columns:
        raise ExecutionError("The verification CSV columns changed.")
    seen: set[tuple[str, str, int, str]] = set()
    for row in rows:
        problem = row["problem"]
        if problem not in EXPECTED_PROBLEMS:
            raise ExecutionError(f"Unexpected problem in verification: {problem}")
        n = int(row["n"])
        if n != EXPECTED_PROBLEMS[problem]:
            raise ExecutionError(f"Unexpected dimension for {problem}: {n}")
        sigma = normalize_sigma(row["sigma"])
        run_index = int(row["run"])
        algorithm = row["algorithm"]
        key = (problem, sigma, run_index, algorithm)
        if key in seen:
            raise ExecutionError(f"Duplicate verification row: {key}")
        seen.add(key)
        if sigma not in EXPECTED_SIGMAS or run_index not in range(1, 6):
            raise ExecutionError(f"Unexpected sigma or run index: {key}")
        if algorithm not in EXPECTED_ALGORITHMS:
            raise ExecutionError(f"Unexpected algorithm: {algorithm}")
        if int(row["seed"]) != 211 * run_index:
            raise ExecutionError(f"Unexpected seed in row: {key}")
        if int(row["maxfun"]) != 200 * n:
            raise ExecutionError(f"Unexpected maxfun in row: {key}")
        if int(row["trace_func_count"]) != int(row["stage3_func_count"]):
            raise ExecutionError(f"Function-count mismatch in row: {key}")
        if int(row["trace_func_count"]) > int(row["maxfun"]):
            raise ExecutionError(f"Function budget exceeded in row: {key}")
        if row["formal_exitflag"] != row["trace_exitflag"]:
            raise ExecutionError(f"Exitflag mismatch in row: {key}")
        if any(row[field] != "1" for field in (
            "formal_exact", "trace_internal_exact", "stage3_exact"
        )):
            raise ExecutionError(f"An exact-equivalence check failed in row: {key}")
        if row["trace_returned_true"] != row["stage3_returned_true"]:
            raise ExecutionError(f"Returned true value mismatch in row: {key}")
    expected_keys = {
        (problem, sigma, run_index, algorithm)
        for problem in EXPECTED_PROBLEMS
        for sigma in EXPECTED_SIGMAS
        for run_index in range(1, 6)
        for algorithm in EXPECTED_ALGORITHMS
    }
    if seen != expected_keys:
        raise ExecutionError("The verification Cartesian product is incomplete.")
    report = md_file.read_text(encoding="utf-8")
    required_report_text = [
        "Strict gate over `180` solver-runs.",
        "| Formal solver exact equality | 180 | 180 |",
        "| Internal trace reconstruction | 180 | 180 |",
        "| Original Stage 3 trajectory exact equality | 180 | 180 |",
    ]
    if any(text not in report for text in required_report_text):
        raise ExecutionError("The Markdown verification report failed its audit.")
    return {
        "status": "passed",
        "solver_runs": 180,
        "formal_exact": 180,
        "trace_internal_exact": 180,
        "stage3_exact": 180,
        "artifacts": [
            {"path": path_label(path), "bytes": path.stat().st_size, "sha256": sha256_file(path)}
            for path in (csv_file, mat_file, md_file)
        ],
    }


def update_task_state(next_state: str) -> None:
    task = read_json(TASK_FILE)
    if task.get("current_state") != INITIAL_STATE:
        raise ExecutionError("The Stage 6 task state changed during execution.")
    task["current_state"] = next_state
    atomic_write_json(TASK_FILE, task)


def record_failed_attempt(state: dict[str, Any], plan: dict[str, Any], message: str) -> None:
    state["last_attempt"] = {
        "plan_sha256": plan["plan_sha256"],
        "action_id": ACTION_ID,
        "status": "failed",
        "message": message,
        "finished_at": utc_now(),
    }
    state["updated_at"] = utc_now()
    atomic_write_json(STATE_FILE, state)


def run(args: argparse.Namespace) -> None:
    with execution_lock():
        plan_file = args.plan.resolve()
        try:
            plan_file.relative_to((EXECUTION_ROOT / "plans").resolve())
        except ValueError as exc:
            raise ExecutionError("The plan file is outside the Stage 6 plans directory.") from exc
        plan = read_json(plan_file)
        validate_plan_schema(plan)
        validate_plan_hash(plan, args.approve)
        state = load_or_create_state()
        if state["state"] != plan["current_state"]:
            raise ExecutionError("The workflow state no longer matches the plan.")
        if state["pending_plan_sha256"] != plan["plan_sha256"]:
            raise ExecutionError("The plan is not the pending approved plan.")
        validate_catalog_action(state["state"])
        if plan["git"] != git_snapshot():
            raise ExecutionError(
                "The Git commit or working-tree snapshot changed after plan approval."
            )
        verify_input_fingerprints(plan["input_fingerprints"])

        execution = plan["execution"]
        run_dir = resolve_execution_path(execution["run_directory"], "run_directory")
        output_dir = resolve_execution_path(execution["output_directory"], "output_directory")
        log_file = resolve_execution_path(execution["log_file"], "log_file")
        if run_dir.exists():
            raise ExecutionError(f"The run directory already exists: {run_dir}")
        output_dir.mkdir(parents=True)
        argv = matlab_argv(output_dir)
        if argv != execution["argv"]:
            raise ExecutionError("The fixed MATLAB argv no longer matches the plan.")
        started_at = utc_now()
        try:
            with log_file.open("w", encoding="utf-8") as log:
                completed = subprocess.run(
                    argv, cwd=WORKSPACE, stdin=subprocess.DEVNULL,
                    stdout=log, stderr=subprocess.STDOUT, check=False,
                )
            if completed.returncode != 0:
                raise ExecutionError(
                    f"MATLAB exited with {completed.returncode}; inspect {log_file}."
                )
            audit = audit_verification(output_dir)
            atomic_write_json(run_dir / "audit.json", audit)
            update_task_state(NEXT_STATE)
        except Exception as exc:
            record_failed_attempt(state, plan, str(exc))
            raise

        state["state"] = NEXT_STATE
        state["pending_plan_sha256"] = None
        state["completed_actions"].append({
            "action_id": ACTION_ID,
            "plan_sha256": plan["plan_sha256"],
            "run_directory": path_label(run_dir),
            "started_at": started_at,
            "finished_at": utc_now(),
            "audit_file": path_label(run_dir / "audit.json"),
        })
        state["last_attempt"] = {
            "plan_sha256": plan["plan_sha256"],
            "action_id": ACTION_ID,
            "status": "passed",
            "finished_at": utc_now(),
        }
        state["updated_at"] = utc_now()
        atomic_write_json(STATE_FILE, state)
        print(json.dumps({
            "status": "passed",
            "action_id": ACTION_ID,
            "previous_state": INITIAL_STATE,
            "current_state": NEXT_STATE,
            "plan_sha256": plan["plan_sha256"],
            "run_directory": str(run_dir),
            "audit": audit,
        }, ensure_ascii=True, indent=2))


def abandon_failed(args: argparse.Namespace) -> None:
    with execution_lock():
        plan_file = args.plan.resolve()
        try:
            plan_file.relative_to((EXECUTION_ROOT / "plans").resolve())
        except ValueError as exc:
            raise ExecutionError("The plan file is outside the Stage 6 plans directory.") from exc
        plan = read_json(plan_file)
        validate_plan_schema(plan)
        validate_plan_hash(plan, args.approve)
        state = load_or_create_state()
        if state["pending_plan_sha256"] != plan["plan_sha256"]:
            raise ExecutionError("The plan is not the pending plan.")
        attempt = state["last_attempt"]
        if (
            not isinstance(attempt, dict)
            or attempt.get("plan_sha256") != plan["plan_sha256"]
            or attempt.get("status") != "failed"
        ):
            raise ExecutionError("Only a recorded failed plan can be abandoned.")
        state["pending_plan_sha256"] = None
        state["updated_at"] = utc_now()
        atomic_write_json(STATE_FILE, state)
        print(json.dumps({
            "status": "abandoned_failed_plan",
            "plan_sha256": plan["plan_sha256"],
            "workflow_state": state["state"],
            "failed_attempt_preserved": True,
        }, ensure_ascii=True, indent=2))


def show_status() -> None:
    with execution_lock():
        state = load_or_create_state()
        print(json.dumps(state, ensure_ascii=True, indent=2))


def write_fake_verification(output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    fields = [
        "problem", "n", "sigma", "run", "seed", "algorithm", "maxfun",
        "trace_func_count", "stage3_func_count", "formal_exitflag",
        "trace_exitflag", "formal_exact", "trace_internal_exact", "stage3_exact",
        "trace_returned_true", "stage3_returned_true",
    ]
    csv_file = output_dir / "stage6_trace_equivalence_verification.csv"
    with csv_file.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for problem, n in EXPECTED_PROBLEMS.items():
            for sigma in (0.1, 0.01):
                for run_index in range(1, 6):
                    for algorithm in ("ds", "cbds"):
                        writer.writerow({
                            "problem": problem, "n": n, "sigma": sigma,
                            "run": run_index, "seed": 211 * run_index,
                            "algorithm": algorithm, "maxfun": 200 * n,
                            "trace_func_count": n, "stage3_func_count": n,
                            "formal_exitflag": 1, "trace_exitflag": 1,
                            "formal_exact": 1, "trace_internal_exact": 1,
                            "stage3_exact": 1, "trace_returned_true": "1.0",
                            "stage3_returned_true": "1.0",
                        })
    (output_dir / "stage6_trace_equivalence_verification.mat").write_bytes(b"fixture")
    (output_dir / "stage6_trace_equivalence_verification.md").write_text(
        "# Stage 6 Trace Equivalence Verification\n\n"
        "Strict gate over `180` solver-runs.\n\n"
        "| Formal solver exact equality | 180 | 180 |\n"
        "| Internal trace reconstruction | 180 | 180 |\n"
        "| Original Stage 3 trajectory exact equality | 180 | 180 |\n",
        encoding="utf-8",
    )


def self_test() -> None:
    plan = {"schema_version": 1, "action_id": ACTION_ID, "payload": [1, 2, 3]}
    plan["plan_sha256"] = plan_hash(plan)
    validate_plan_hash(plan, plan["plan_sha256"])
    tampered = json.loads(json.dumps(plan))
    tampered["payload"].append(4)
    try:
        validate_plan_hash(tampered)
    except ExecutionError:
        pass
    else:
        raise AssertionError("Tampered plans must be rejected.")
    try:
        validate_plan_hash(plan, "0" * 64)
    except ExecutionError:
        pass
    else:
        raise AssertionError("Incorrect approval hashes must be rejected.")
    try:
        validate_implemented_action("bds.stage6.run_tier1")
    except ExecutionError:
        pass
    else:
        raise AssertionError("Unimplemented actions must be rejected.")
    try:
        validate_catalog_action(NEXT_STATE)
    except ExecutionError:
        pass
    else:
        raise AssertionError("Actions from an incorrect workflow state must be rejected.")
    with tempfile.TemporaryDirectory(prefix="stage6-executor-test-") as directory:
        output_dir = Path(directory)
        write_fake_verification(output_dir)
        audit = audit_verification(output_dir)
        assert audit["solver_runs"] == 180
        csv_file = output_dir / "stage6_trace_equivalence_verification.csv"
        text = csv_file.read_text(encoding="utf-8")
        csv_file.write_text(text.replace(",1,1,1,1.0,1.0", ",0,1,1,1.0,1.0", 1), encoding="utf-8")
        try:
            audit_verification(output_dir)
        except ExecutionError:
            pass
        else:
            raise AssertionError("Failed exact-equivalence rows must be rejected.")
    print(
        "PASS plan tamper detection, approval hash, fixed action, and 180-row audit tests."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("--response", type=Path)
    prepare_parser.add_argument("--action-id")
    prepare_parser.add_argument("--direct-user-authorization", action="store_true")
    run_parser = subparsers.add_parser("run")
    run_parser.add_argument("--plan", type=Path, required=True)
    run_parser.add_argument("--approve", required=True)
    abandon_parser = subparsers.add_parser("abandon-failed")
    abandon_parser.add_argument("--plan", type=Path, required=True)
    abandon_parser.add_argument("--approve", required=True)
    subparsers.add_parser("status")
    subparsers.add_parser("self-test")
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare(args)
        elif args.command == "run":
            run(args)
        elif args.command == "abandon-failed":
            abandon_failed(args)
        elif args.command == "status":
            show_status()
        else:
            self_test()
    except ExecutionError as exc:
        print(f"REJECTED: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
