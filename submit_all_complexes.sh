#!/bin/bash

# Submit all 5 complexes to SLURM queue
# Each complex will be assigned to a different GPU node

for i in {1..5}; do
    echo "Submitting Complex $i"
    sbatch run_md_complex_${i}.slurm
    sleep 2  # Small delay between submissions
done

echo "All jobs submitted. Check status with: squeue"
