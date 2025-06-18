#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path to this script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define paths
input_dir="$script_dir/../results/unique_sequences"
output_dir="$script_dir/../results/qgrs"

# Start time
start_time=$(date +%s)

# Create output directory
mkdir -p "$output_dir"

# Process each input file
for input_file in "$input_dir"/*.fasta; do
    output_file="$output_dir/$(basename "${input_file%_combined.fasta}_results.tsv")"

    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' not found. Skipping..."
        continue
    fi

    echo "Processing file: $input_file"
    echo "Saving results to: $output_file"

    # Write header row to the output file
    echo -e "input_sequence\tT1\tT2\tT3\tT4\tTS\tGS\tSEQ" > "$output_file"

    # Count total sequences in the file
    total_sequences=$(grep -c '^>' "$input_file")

    # Initialize counter
    counter=0

    # Read sequences from the FASTA file
    awk '/^>/ {if (seq) print seq; print; seq=""; next} {seq=seq$0} END {if (seq) print seq}' "$input_file" | \
    while read -r header; do
        read -r sequence

        # Increment counter
        counter=$((counter + 1))

        # Display progress
        echo "Processing sequence $counter/$total_sequences"

        # Run qgrs for the sequence
        qgrs_output=$(echo "$sequence" | /Users/esther/Desktop/G4/qgrs-cpp/qgrs -t 2 -s 17 -csv 2>/dev/null)

        # Skip the sequence if no QGRS are found
        if [[ "$qgrs_output" == *"No QGRS found"* ]]; then
            continue
        fi

        # Extract valid rows and write to the file
        echo "$qgrs_output" | tail -n +3 | while IFS=',' read -r id t1 t2 t3 t4 ts gs seq; do
            if [[ -n "$t1" && -n "$seq" ]]; then
                echo -e "$sequence\t$t1\t$t2\t$t3\t$t4\t$ts\t$gs\t$seq" >> "$output_file"
            fi
        done
    done

    echo "Finished processing: $input_file"
done

# End time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "All files processed. Results saved to $output_dir."
echo "Script finished in $elapsed_time seconds."