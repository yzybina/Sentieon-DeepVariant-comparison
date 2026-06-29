#!/usr/bin/env bash
#SBATCH --job-name=sentieon_HG002
#SBATCH --partition=medium
#SBATCH --nodes=1
#SBATCH --mem=70gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --output=logs/sentieon_HG002_2.1%j.log
#SBATCH --time=12:00:00

export SENTIEON_LICENSE=/private/home/yzybina/sentieon/UCSC_Paten_lab_eval.lic
export PATH=$PATH:/private/home/yzybina/sentieon/sentieon-genomics-202503.03/bin
export PATH=$PATH:/private/home/yzybina/vg_1.74.1

source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2

sentieon-cli sentieon-pangenome \
  -r support_files/hg38_ucsc.fa \
  --hapl /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.hapl   \
  --gbz /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz   \
  -m support_files/SentieonIlluminaPangenomeRealignWGS1.2.bundle \
  --pop_vcf support_files/pop-v20-20260528.vcf.gz \
  --r1_fastq HG002_R1.fq.gz \
  --r2_fastq HG002_R2.fq.gz \
  --readgroup "@RG\tID:HG002-1\tSM:HG002\tLB:HG002-LB-1\tPL:ILLUMINA" \
  -b support_files/hg38_canonical.bed \
  --dbsnp support_files/Homo_sapiens_assembly38.dbsnp138.vcf.gz \
  --pcr_free \
  -t 32 \
  --skip_pangenome_name_checks \
  Sentieon_output/HG002_pangenome_2.1graph_1.2model.vcf.gz

