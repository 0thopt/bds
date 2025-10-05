ARTIFACT_NAME=$(ls | grep "profile_optiprofiler" | head -n 1)
BASE_INFO=$(echo $ARTIFACT_NAME | grep -o "[^_]*_[^_]*_[^_]*_\(small\|big\|large\)")