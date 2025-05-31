#!/bin/bash

# Define input and output directories
input_dir="/Users/esther/Desktop/G4/data/50%_GC"
output_dir="/Users/esther/Desktop/G4/data/50%_GC_unique"

# List of input files
#input_files=("2nd_combined.fasta" "3rd_combined.fasta" "4th_combined.fasta" "5th_combined.fasta")

# Create output directory
mkdir -p "$output_dir"

# Process each input file
for input_path in "$input_dir"/*.fasta; do
    input_file=$(basename "$input_path")
    output_path="$output_dir/$input_file"

    # Check if the input file exists
    if [[ ! -f "$input_path" ]]; then
        echo "Error: Input file '$input_path' not found. Skipping..."
        continue
    fi

    echo "Processing file: $input_path"

    # Use awk to remove duplicate sequences while preserving headers
    awk '/^>/ {header=$0; getline seq; if (!seen[seq]++) {print header; print seq}}' "$input_path" > "$output_path"

    echo "Finished processing. Unique sequences saved to: $output_path"
done

echo "All files processed. Unique sequences saved in $output_dir."
