ARTIFACT_NAME=$(ls | grep "profile_optiprofiler" | head -n 1)
BASE_INFO=$(echo $ARTIFACT_NAME | sed -n 's/.*optiprofiler_\(.*\)_\(small\|big\).*/\1_\2/p')