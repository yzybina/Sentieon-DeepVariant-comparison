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


export PATH=/private/home/yzybina/vg/bin:$PATH
#5.7.26 this script is updated to backconvert first the graph to a vresion that works for deepVariant, due to eralier error: 
#pangenome_aware_deepvariant-1.10.0: the error read: GBZ: Expected v1, got v2


# Count kmers from reads
#kmc: Counts 29-mers from your raw reads and stores them in a .kff file. 
#This is the only step that touches the raw reads. Its output represents "what kmers are present in this sample."
# kmc -k29 -okff -t16 \
#     /private/groups/patenlab/anovak/projects/hprc/lr-giraffe/reads/real/illumina/HG002/HG002.novaseq.pcr-free.40x.full.fq.gz \
#     vg_output/HG002 \
#     vg_output/tmp

#Uses the kmer counts (.kff) as evidence of which haplotypes in the pangenome are consistent with your sample. Produces a reduced, sample-specific graph
#when using the d46 filtered graph this step is not needed
# /private/home/yzybina/vg_1.74.1/vg haplotypes -v 2 -t 16 \
#     --include-reference \
#     --diploid-sampling \
#     -i /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.hapl \
#     -k vg_output/HG002.kff \
#     -g vg_output/HG002.gbz \
#     /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz

#vg autoindex: Builds mapping indexes (distance index, minimizer index, zipcodes) from the sample-specific graph. No reads involved at all.
# /private/home/yzybina/vg_1.74.1/vg autoindex \
#     --prefix vg_output/HG002 \
#     --workflow giraffe \
#     --no-guessing \
#     -G vg_output/HG002.gbz \
#     --threads 16


#Maps the raw reads to the indexed sample-specific graph and produces a BAM
# vg giraffe \
#   -Z /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.gbz \
#   -d /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.dist \
#   -m /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.shortread.withzip.min \
#   -z /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.shortread.zipcodes \
#   -f /private/groups/patenlab/anovak/projects/hprc/lr-giraffe/reads/real/illumina/HG002/HG002.novaseq.pcr-free.40x.full.fq.gz \
#   -i \
#   -N HG002 \
#   --ref-name GRCh38 \
#   --threads 16 \
#   --output-format BAM | \
#   samtools sort -@ 4 -o vg_output/HG002_eval.aligned.sorted.bam

#samtools index vg_output/HG002_eval.aligned.sorted.bam #Sorts and indexes the BAM so it can be randomly accessed by position, which DeepVariant requires.

# samtools view -h vg_output/HG002_eval.aligned.sorted.bam | \
#   sed -e "s/GRCh38#0#//g" | \
#   samtools sort --threads 10 -m 2G -O BAM > vg_output/HG002_eval.aligned.sorted.renamed.bam

#samtools index -@$(nproc) vg_output/HG002_eval.aligned.sorted.renamed.bam



#Rerun vg haplotypes with --num-haplotypes 16 to make a separate GBZ just for DeepVariant
# /private/home/yzybina/vg_1.74.1/vg haplotypes -v 2 -t 16 \
#     --include-reference \
#     --num-haplotypes 16 \
#     -i /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.hapl \
#     -k vg_output/HG002.kff \
#     -g vg_output/HG002.16hap.gbz \
#     /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz

# then back - convert the graph
#/private/home/yzybina/vg/bin/vg gbwt --gbz-v1 -Z vg_output/HG002.16hap.gbz -g vg_output/HG002.16hap.v1.gbz

BIN_VERSION="pangenome_aware_deepvariant-1.10.0"

docker pull google/deepvariant:"${BIN_VERSION}"

docker run \
  -v "$(pwd):/data" \
  --shm-size 15gb \
  google/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_pangenome_aware_deepvariant \
  --gbz_shared_memory_size_gb 15 \
  --model_type WGS \
  --ref /data/support_files/hg38_ucsc.fa \
  --reads /data/vg_output/HG002_eval.aligned.sorted.renamed.bam \
  --pangenome /data/vg_output/HG002.16hap.v1.gbz \
  --output_vcf /data/vg_output/HG002_eval.output.pangenome.vcf.gz \
  --output_gvcf /data/vg_output/HG002_eval.output.pangenome.g.vcf.gz \
  --num_shards 16 \
  --intermediate_results_dir /data/vg_output/intermediate_2

#WGS model that is best suited for short-read WGS data.