#!/bin/bash

# Directory containing your .merge.fasta.gz files
input_dir="/Users/esther/Desktop/G4/NGS_30%_20%_library/50%_GC"

# Output directory for combined FASTA files
output_dir="/Users/esther/Desktop/G4/data/50%_GC"
mkdir -p "$output_dir"

# Loop through all .merge.fasta.gz files in the directory
#for file in "$input_dir"/*.merge.fasta.gz; do
for file in "$input_dir"/*.fasta.gz; do
  # Check if there are files matching the pattern
  if [ -f "$file" ]; then
    # Extract the base name of the file (e.g., file.merge.fasta.gz -> file)
    # base_name=$(basename "$file" .merge.fasta.gz)
    base_name=$(basename "$file" .fasta.gz)
    # Define the output file name
    output_file="$output_dir/${base_name}_combined.fasta"
    echo "Processing $file -> $output_file..."
    # Decompress the file and save the content into its own output file
    gunzip -c "$file" > "$output_file"
  else
    echo "No .merge.fasta.gz files found in $input_dir"
  fi
done

echo "All files have been processed. Check $output_dir for results."
