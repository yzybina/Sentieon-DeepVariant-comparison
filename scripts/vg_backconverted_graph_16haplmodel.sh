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


BIN_VERSION="pangenome_aware_deepvariant-1.10.0"

docker pull google/deepvariant:"${BIN_VERSION}"

MODEL_CKPT="/data/support_files/dv_16hapl_model/checkpoint-153600-0.98945-1"


docker run \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/data" \
  --shm-size 15gb \
  google/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_pangenome_aware_deepvariant \
  --gbz_shared_memory_size_gb 15 \
  --model_type WGS \
  --customized_model "${MODEL_CKPT}" \
  --ref /data/support_files/hg38_ucsc.fa \
  --reads /data/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
  --pangenome /data/vg_output_pangenome/HG002.16hap.v1.gbz \
  --output_vcf /data/vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.vcf.gz \
  --output_gvcf /data/vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.g.vcf.gz \
  --num_shards 16 \
  --intermediate_results_dir /data/vg_output_pangenome/intermediate

#WGS model that is best suited for short-read WGS data.