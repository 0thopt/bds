#!/bin/bash

# 1. 复制文件，将grad_05改为grad_04
echo "Step 1: Copying files..."
for file in profile_cbds_grad_05*.yml; do 
    cp "$file" "${file/grad_05/grad_04}"
done
echo "Step 1: Files copied successfully."

# 2. 替换文件内容中的05为04
echo "Step 2: Replacing '05' with '04' in new files..."
sed -i '' 's/05/04/g' profile_cbds_grad_04*.yml
echo "Step 2: Content replaced successfully."

# 3. 替换[5 1e8]为[4 1e8]
echo "Step 3: Replacing '[5 1e8]' with '[4 1e8]' in new files..."
sed -i '' 's/\[5 1e8\]/\[4 1e8\]/g' profile_cbds_grad_04*.yml
echo "Step 3: Content replaced successfully."

echo "All operations completed successfully!"