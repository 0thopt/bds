#!/bin/bash

name=$1

# Match a trailing profile timestamp: yy_MM_dd_HH_mm[_ss] or yyyy_MM_dd_HH_mm[_ss].
timestamp_re='_([0-9]{2}|[0-9]{4})_(0[1-9]|1[0-2])_(0[1-9]|[12][0-9]|3[01])_([01][0-9]|2[0-3])_[0-5][0-9](_[0-5][0-9])?$'

if [[ "$name" =~ $timestamp_re ]]; then
    printf '%s\n' "${name:0:${#name}-${#BASH_REMATCH[0]}}"
else
    printf '%s\n' "$name"
fi
