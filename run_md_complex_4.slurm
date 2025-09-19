#!/bin/bash
#SBATCH --job-name=comp_4
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=28        # Use all CPU cores on one node
#SBATCH --gres=gpu:4              # Use all 4 GPUs per node
#SBATCH --time=24:00:00           # Adjust based on your simulation length
#SBATCH --output=complex_4/complex_4_%j.out
#SBATCH --error=complex_4/complex_4_%j.err
#SBATCH --nodelist=gpu02

# Load required modules
module load GROMACS

# Set working directory
WORKDIR="/home/faruk/md_simulations/complex_4"
cd $WORKDIR

echo "Starting MD simulation for Complex 4"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURMD_NODENAME"
echo "Working directory: $PWD"
echo "Start time: $(date)"

# Set OpenMP threads (should equal cpus-per-task)
export OMP_NUM_THREADS=28

# Step 1: Energy minimization
echo "Step 1: Energy minimization"
gmx grompp -f input/minim.mdp -c input/solv_ions.gro -p topology/topol.top -o equilibration/em.tpr -maxwarn 1
gmx mdrun -v -deffnm equilibration/em -gpu_id 0123 -ntmpi 1

# Step 2: NVT equilibration
echo "Step 2: NVT equilibration"
gmx grompp -f input/nvt.mdp -c equilibration/em.gro -r equilibration/em.gro -p topology/topol.top -o equilibration/nvt.tpr
gmx mdrun -v -deffnm equilibration/nvt -gpu_id 0123 -ntmpi 1 -s equilibration/nvt

# Step 3: NPT equilibration
echo "Step 3: NPT equilibration"
gmx grompp -f input/npt.mdp -c equilibration/nvt.gro -r equilibration/nvt.gro -t equilibration/nvt.cpt -p topology/topol.top -o equilibration/npt.tpr
gmx mdrun -v -deffnm equilibration/npt -gpu_id 0123 -ntmpi 1 -s equilibration/nvt

# Step 4: Production MD
echo "Step 4: Production MD simulation"
gmx grompp -f input/md.mdp -c equilibration/npt.gro -t equilibration/npt.cpt -p topology/topol.top -o production/md_0_1.tpr
gmx mdrun -v -deffnm production/md_0_1 -gpu_id 0123 -ntmpi 1 -s equilibration/nvt

echo "Simulation completed for Complex 4"
echo "End time: $(date)"

# Basic analysis
echo "Running basic analysis..."
cd analysis

# RMSD analysis
echo "1 4 \n 4 4" | gmx rms -s ../production/md_0_1.tpr -f ../production/md_0_1.xtc -o rmsd.xvg -tu ns

# Radius of gyration
echo "1" | gmx gyrate -s ../production/md_0_1.tpr -f ../production/md_0_1.xtc -o gyrate.xvg

# Potential energy
gmx energy -f ../production/md_0_1.edr -o potential.xvg << ENERGY_EOF
10
0
ENERGY_EOF

echo "Basic analysis completed for Complex 4"
echo "Check the analysis/ directory for results"


