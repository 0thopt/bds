#!/bin/bash

# Define keywords to search for PDF files
keywords=(
    "plain"
    "noisy_1_no_rotation"
    "noisy_2_no_rotation"
    "noisy_3_no_rotation"
    "noisy_4_no_rotation"
    "linearly_transformed"
    "rotation_noisy_1"
    "rotation_noisy_2"
    "rotation_noisy_3"
    "rotation_noisy_4"
    "permuted"
    "permuted_noisy_1"
    "permuted_noisy_2"
    "permuted_noisy_3"
    "permuted_noisy_4"
    "quantized"
    "perturbed_x0"
    "random_nan"
    "truncated"
)

output_file="merged.pdf"
pdf_files=()

# Print all PDF files for debugging
echo "Found these PDF files:"
find . -maxdepth 1 -name "summary*.pdf" -type f | while read -r file; do
    echo "  $file"
done

# Search for PDF files with keywords
for keyword in "${keywords[@]}"; do
    echo "Searching for keyword: $keyword"
    case "$keyword" in
        "perturbed_x0")
            found_files=$(find . -maxdepth 1 -type f -name "summary*perturbed_x0*.pdf" | sort -V)
            ;;
        "random_nan")
            found_files=$(find . -maxdepth 1 -type f -name "summary*random_nan*.pdf" | sort -V)
            ;;
        "truncated")
            found_files=$(find . -maxdepth 1 -type f -name "summary*truncated*.pdf" | sort -V)
            ;;
        *)
            found_files=$(find . -maxdepth 1 -type f -name "summary*${keyword}.pdf" -o -name "summary*${keyword}_*.pdf" | sort -V)
            ;;
    esac
    
    # Add found files to array if they're not already included
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            # Check if file is already in pdf_files array
            already_included=0
            for existing_file in "${pdf_files[@]}"; do
                if [ "$existing_file" = "$file" ]; then
                    already_included=1
                    break
                fi
            done
            if [ $already_included -eq 0 ]; then
                pdf_files+=("$file")
            fi
        fi
    done <<< "$found_files"
done

# Print the array content for debugging
echo -e "\nFiles in order of keywords (no duplicates):"
printf '%s\n' "${pdf_files[@]}"

# Print total number of files found
echo -e "\nTotal files found: ${#pdf_files[@]}"

# Merge PDF files
if [ ${#pdf_files[@]} -gt 0 ]; then
    pdfunite "${pdf_files[@]}" "$output_file"
    echo "Merge successfully: $output_file"
else
    echo "There are no PDF files to merge."
    echo -e "\nAll PDF files in current directory:"
    find . -maxdepth 1 -name "summary*.pdf" -type f
fi