#!/bin/bash

# Path to the directory containing the .fasta files
input_dir="/Users/esther/Desktop/G4/data/50%_GC_unique"

# Output directory for RNAfold results
output_dir="/Users/esther/Desktop/G4/results/RNAfold/50%_GC"

# Start time
start_time=$(date +%s)

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all .fasta files in the input directory
for input_file in "$input_dir"/*.fasta; do
    # Extract the base name of the file (without extension)
    base_name=$(basename "$input_file" .fasta)
    
    # Define the output file name
    output_file="$output_dir/${base_name}_RNAfold.out"
    
    # Run RNAfold with options to suppress .ps file generation
    echo "Processing $input_file..."
    RNAfold -d2 -g --noLP --noPS < "$input_file" > "$output_file"
    
    echo "Output saved to $output_file"
done

# End time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Script finished in $elapsed_time seconds."
echo "All .fasta files have been processed."
