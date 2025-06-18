#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path to this script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths
input_dir="$script_dir/../results/unique_sequences"
output_dir="$script_dir/../results/G4H_G4NN"
screener_script="$script_dir/../library/g4rna_screener/screen.py"
model_file="$script_dir/../library/g4rna_screener/G4RNA_2016-11-07.pkl"

# Create output directory
mkdir -p "$output_dir"

# Start time
start_time=$(date +%s)

# Process each input file
for file in "$input_dir"/*.fasta; do
    base_name="$(basename "$file" _combined.fasta)"
    output="$output_dir/${base_name}_results.tsv"

    echo "Running G4RNA screener on: $file"
    python2 "$screener_script" \
        "$file" \
        -a "$model_file" \
        -w 60 \
        -s 10 \
        -c description sequence G4H G4NN \
        -v \
        -e \
        > "$output"

    # Remove the first 4 lines from the output file
    tail -n +5 "$output" > "${output}.tmp" && mv "${output}.tmp" "$output"

    echo "Finished: $output"

done

# End time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Script finished in $elapsed_time seconds."
