#!/usr/bin/env bash
#SBATCH --job-name=gamsort
#SBATCH --partition=long
#SBATCH --nodes=1
#SBATCH --mem=65gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --output=logs/gamsort%j.log
#SBATCH --time=22:00:00



/private/home/yzybina/vg_1.74.1/vg gamsort -p -t 16 \
  -i /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.gam.gai \
  /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.gam \
  > /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.gam