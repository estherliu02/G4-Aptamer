#!/bin/bash

# Define input and output directories
input_dir="/Users/esther/Desktop/G4/data/50%_GC_unique"
output_dir="/Users/esther/Desktop/G4/results/G4H_G4NN/50%_GC"
mkdir -p "$output_dir"

# Start time
start_time=$(date +%s)

# Process each input file
for file in "$input_dir"/*.fasta; do
    output="$output_dir/$(basename "${file%.fasta}_results.tsv")"

    python2 /Users/esther/Desktop/G4/g4rna_screener/screen.py \
        "$file" \
        -a /Users/esther/Desktop/G4/g4rna_screener/G4RNA_2016-11-07.pkl \
        -w 60 \
        -s 10 \
        -c description sequence start cGcC G4H G4NN \
        -v \
        -e \
        > "$output"
done

# End time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Script finished in $elapsed_time seconds."