#!/usr/bin/env bash
set -euo pipefail    # safer bash defaults

# Absolute path to the directory where this script resides
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Input and output directories (relative to the script location)
input_dir="$script_dir/../data"
output_dir="$script_dir/../results/combined_fasta_files"

# Create the output directory if it doesn’t exist
mkdir -p "$output_dir"

echo "Reading from:   $input_dir"
echo "Writing to:     $output_dir"
echo

# Loop through all .fasta.gz files in the input directory
shopt -s nullglob   # prevent literal pattern if no matches
for file in "$input_dir"/*.fasta.gz; do
  base_name="$(basename "$file" .fasta.gz)"
  output_file="$output_dir/${base_name}_combined.fasta"

  echo "Processing $(basename "$file") → $(basename "$output_file") ..."
  gunzip -c "$file" > "$output_file"
done
shopt -u nullglob

echo
echo "Done. Combined FASTA files are in: $output_dir"
