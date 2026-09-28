#!/usr/bin/env bash
#SBATCH --job-name=autoindex
#SBATCH --partition=long
#SBATCH --nodes=1
#SBATCH --mem=200gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --output=logs/autoindex.1%j.log
#SBATCH --time=24:00:00



source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2


/private/home/yzybina/vg_1.74.1/vg autoindex \
    --prefix vg_output_pangenome/HG002 \
    --workflow giraffe \
    --no-guessing \
    -G vg_output_pangenome/HG002.gbz \
    --threads 16
