#!/bin/bash

set -e

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
strip_script="$script_dir/strip_profile_timestamp.sh"

check_strip() {
    local input=$1
    local expected=$2
    local actual

    actual=$(bash "$strip_script" "$input")
    if [ "$actual" != "$expected" ]; then
        echo "Expected: $expected"
        echo "Actual:   $actual"
        echo "Input:    $input"
        exit 1
    fi
}

check_strip "orig_cbds_newuoa_small_s2mpj_26_06_16_14_23" \
    "orig_cbds_newuoa_small_s2mpj"
check_strip "orig_cbds_newuoa_small_s2mpj_26_06_16_14_23_45" \
    "orig_cbds_newuoa_small_s2mpj"
check_strip "orig_cbds_newuoa_small_s2mpj_2026_06_16_14_23" \
    "orig_cbds_newuoa_small_s2mpj"
check_strip "orig_cbds_newuoa_small_s2mpj_2026_06_16_14_23_45" \
    "orig_cbds_newuoa_small_s2mpj"
check_strip "cbds_func_window_size_20_tol_06_s2mpj_big_plain_26_06_16_14_23" \
    "cbds_func_window_size_20_tol_06_s2mpj_big_plain"
check_strip "cbds_func_window_size_20_tol_06_s2mpj_big_plain_26_06_16_14_23_45" \
    "cbds_func_window_size_20_tol_06_s2mpj_big_plain"
check_strip "name_without_timestamp" \
    "name_without_timestamp"
check_strip "name_with_invalid_month_26_13_16_14_23" \
    "name_with_invalid_month_26_13_16_14_23"
check_strip "name_with_invalid_second_26_06_16_14_23_60" \
    "name_with_invalid_second_26_06_16_14_23_60"

echo "strip_profile_timestamp tests passed."
