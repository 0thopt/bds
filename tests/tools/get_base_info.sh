BASE_INFO=""

# Preferred path: extract from workflow file name (works for all profile workflows).
# Example:
#   owner/repo/.github/workflows/profile_orig_cbds_nomad_small_s2mpj.yml@refs/heads/main
# -> BASE_INFO=orig_cbds_nomad_small_s2mpj
if [ -n "$GITHUB_WORKFLOW_REF" ]; then
	WORKFLOW_PATH=${GITHUB_WORKFLOW_REF%@*}
	WORKFLOW_FILE=${WORKFLOW_PATH##*/}
	case "$WORKFLOW_FILE" in
		profile_*.yml)
			BASE_INFO=${WORKFLOW_FILE#profile_}
			BASE_INFO=${BASE_INFO%.yml}
			;;
	esac
fi

# Fallback path: derive from downloaded artifact name when workflow ref is unavailable.
if [ -z "$BASE_INFO" ]; then
	ARTIFACT_NAME=""
	for entry in profile_optiprofiler*; do
		if [ -e "$entry" ]; then
			ARTIFACT_NAME=$entry
			break
		fi
	done
	BASE_INFO=${ARTIFACT_NAME#profile_optiprofiler_}
fi

# Normalize separators for downstream file naming.
BASE_INFO=$(printf '%s' "$BASE_INFO" | tr '-' '_')