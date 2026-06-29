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


# /private/home/yzybina/vg_1.74.1/vg autoindex \
#     --workflow sampling \
#     --prefix support_files/hprc-v2.0-mc-grch38-eval \
#     -G /private/groups/cgl/hprc-graphs/hprc-v2.0-feb28/hprc-v2.0-mc-grch38-eval/hprc-v2.0-mc-grch38-eval.gbz \
#     --threads 16

/private/home/yzybina/vg_1.74.1/vg autoindex \
    --workflow sampling \
    --prefix support_files/hprc-v2.0-mc-grch38 \
    -G /private/groups/cgl/hprc-graphs/hprc-v2.0-feb28/hprc-v2.0-mc-grch38/hprc-v2.0-mc-grch38.gbz \
    --threads 16