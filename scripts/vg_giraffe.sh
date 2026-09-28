#!/usr/bin/env bash
#SBATCH --job-name=vg_HG002
#SBATCH --partition=medium
#SBATCH --nodes=1
#SBATCH --mem=10gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --output=logs/vg_HG002_%j.log
#SBATCH --time=10:00:00

export PATH=$PATH:/private/home/yzybina/vg

# Count kmers from reads
#kmc: Counts 29-mers from your raw reads and stores them in a .kff file. 
#This is the only step that touches the raw reads. Its output represents "what kmers are present in this sample."
kmc -k29 -m128 -okff -t16 \
    /private/groups/patenlab/anovak/projects/hprc/lr-giraffe/reads/real/illumina/HG002/HG002.novaseq.pcr-free.40x.full.fq.gz \
    vg_output/HG002 \
    vg_output/tmp

#Uses the kmer counts (.kff) as evidence of which haplotypes in the pangenome are consistent with your sample. Produces a reduced, sample-specific graph
vg haplotypes \
    -k vg_output/HG002.kff \
    -i /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38/hprc-v2.1-mc-grch38.hapl \
    -d /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38/hprc-v2.1-mc-grch38.d46.dist \
    --num-haplotypes 4 \
    --haploid-scoring \
    --ban-sample HG002 \
    --include-reference \
    -g vg_output/HG002.gbz \
    /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38/hprc-v2.1-mc-grch38.gbz

#vg autoindex: Builds mapping indexes (distance index, minimizer index, zipcodes) from the sample-specific graph. No reads involved at all.
vg autoindex \
    --prefix vg_output/HG002 \
    --no-guessing \
    --workflow giraffe \
    -G vg_output/HG002.gbz \
    --threads 16

#Maps the raw reads to the indexed sample-specific graph and produces a BAM. 
vg giraffe \
  -Z vg_output/HG002.gbz \
  -d vg_output/HG002.dist \
  -m vg_output/HG002.shortread.withzip.min \
  -z vg_output/HG002.shortread.zipcodes \
  -f /private/groups/patenlab/anovak/projects/hprc/lr-giraffe/reads/real/illumina/HG002/HG002.novaseq.pcr-free.40x.full.fq.gz \
  -i \
  -N HG002 \
  --ref-name GRCh38 \
  --threads 16 \
  --output-format BAM \
  > vg_output/HG002.aligned.bam

#Sorts and indexes the BAM so it can be randomly accessed by position, which DeepVariant requires.
samtools sort -@ 16 -o vg_output/HG002.aligned.sorted.bam vg_output/HG002.aligned.bam
samtools index vg_output/HG002.aligned.sorted.bam



BIN_VERSION="pangenome_aware_deepvariant-1.10.0"

docker pull google/deepvariant:"${BIN_VERSION}"

docker run \
  -v "$(pwd):/data" \
  --shm-size 12gb \
  google/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_pangenome_aware_deepvariant \
  --model_type WGS \
  --ref /data/support_files/hg38_ucsc.fa \
  --reads /data/vg_output/HG002.aligned.sorted.renamed.bam \
  --pangenome /data/vg_output/HG002.gbz \
  --output_vcf /data/vg_output/HG002.output.pangenome.vcf.gz \
  --output_gvcf /data/vg_output/HG002.output.pangenome.g.vcf.gz \
  --num_shards 16 \
  --intermediate_results_dir /data/vg_output/intermediate