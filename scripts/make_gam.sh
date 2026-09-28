#!/usr/bin/env bash
#SBATCH --job-name=vg_HG002
#SBATCH --partition=long
#SBATCH --nodes=1
#SBATCH --mem=100gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --output=logs/vg_HG002_backconverted%j.log
#SBATCH --time=20:00:00


source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2

VG=/private/home/yzybina/vg_1.74.1/vg

"$VG" giraffe \
  -Z vg_output_pangenome/HG002.gbz \
  -d vg_output_pangenome/HG002.dist \
  -m vg_output_pangenome/HG002.shortread.withzip.min \
  -z vg_output_pangenome/HG002.shortread.zipcodes \
  -f /private/groups/patenlab/anovak/projects/hprc/lr-giraffe/reads/real/illumina/HG002/HG002.novaseq.pcr-free.40x.full.fq.gz \
  -i \
  -N HG002 \
  --ref-name GRCh38 \
  --threads 16 \
  --output-format GAM \
  > vg_output_pangenome/HG002_eval.aligned.gam