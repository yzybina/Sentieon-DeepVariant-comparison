#!/usr/bin/env bash
#SBATCH --job-name=giraffe_HG003
#SBATCH --nodes=1
#SBATCH --output=logs/giraffe_HG003_%j.log
#SBATCH --time=30:00:00
#SBATCH --partition=long
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2

toil clean file:/private/groups/patenlab/yulia/sentieon_benchmarking/jobstore_giraffe

toil-wdl-runner \
  --jobstore ./jobstore_giraffe \
  --batchSystem slurm \
  --slurmPartition long \
  --slurmTime 30:00:00 \
  --wdlContainer singularity \
  vg_wdl/workflows/giraffe.wdl \
  WDL_giraffe/giraffe_003_inputs.json \
  --wdlOutputDirectory ./giraffe_out \
  --wdlOutputFile giraffe_003_outputs.json

