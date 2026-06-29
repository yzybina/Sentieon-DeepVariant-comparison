#!/usr/bin/env bash
#SBATCH --job-name=aardvark
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --mem=30gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --output=logs/aardvark_%j.log
#SBATCH --time=1:00:00

#last job: 34079812
# Job ID: 34079812
# Cluster: phoenix
# User/Group: yzybina/prismuser
# State: COMPLETED (exit code 0)
# Nodes: 1
# Cores per node: 16
# CPU Utilized: 00:11:49
# CPU Efficiency: 47.14% of 00:25:04 core-walltime
# Job Wall-clock time: 00:01:34
# Memory Utilized: 23.47 GB
# Memory Efficiency: 46.94% of 50.00 GB

source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2

#Sentieon on 2.0 graph to truth set:
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.0_evalgraph.filtered.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
#     --output-dir aardvark_results/sentieon_2.0_evalgraph_filtered \
#     --stratification /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
#     --threads 16


# sentieon filtered with bcftools view -f "PASS,." to truth set
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
#     --output-dir aardvark_results/sentieon_2.1_evalgraph_filtered \
#     --stratification /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
#     --threads 16

# sentieon 1.2 model bundleL
aardvark compare \
    --reference support_files/hg38_ucsc.fa \
    --truth-vcf truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
    --query-vcf Sentieon_output/HG002_pangenome_2.1graph_1.2model.filtered.vcf.gz \
    --regions truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
    --output-dir aardvark_results/sentieon_2.1graph_1.2model_filtered \
    --stratification support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
    --threads 16


# Pangenome DV to truth set
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.output.pangenome.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
#     --output-dir aardvark_results/vg_pangenomeDV \
#     --stratification /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
#     --threads 16

# Pangenome DV filtered with bcftools view -f "PASS,." to truth set 
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.output.pangenome.filtered.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
#     --output-dir aardvark_results/vg_pangenomeDV_filtered \
#     --stratification /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
#     --threads 16

#Pangenome DV + 16haplotype model, filtered with bcftools view -f "PASS,." to truth set
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.filtered.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
#     --output-dir aardvark_results/vg_pangenomeDV_16hapmodel_filtered \
#     --stratification /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/GRCh38@all/GRCh38-all-stratifications.tsv \
#     --threads 16


# sentieon 2 identical runs:
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph_testrerun.vcf.gz \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_canonical.bed \
#     --output-dir aardvark_results/sentieon2.1vs2.1 \
#     --threads 16

# # sentieon 2.0 to 2.1:
# aardvark compare \
#     --reference /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_ucsc.fa \
#     --truth-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.vcf.gz \
#     --query-vcf /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.0_evalgraph.vcf.gz  \
#     --regions /private/groups/patenlab/yulia/sentieon_benchmarking/support_files/hg38_canonical.bed \
#     --output-dir aardvark_results/sentieon2.0vs2.1 \
#     --threads 16