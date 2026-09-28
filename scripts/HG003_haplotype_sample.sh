#!/usr/bin/env bash
#SBATCH --job-name=vg_HG003
#SBATCH --partition=long
#SBATCH --nodes=1
#SBATCH --mem=100gb
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --output=logs/vg_HG003_haplotypes%j.log
#SBATCH --time=20:00:00


source /private/home/yzybina/miniconda3//etc/profile.d/conda.sh
conda activate sentieon-cli-1.5.2

export PATH=/private/home/yzybina/vg/bin:$PATH

# Count kmers from reads
kmc -k29 -okff -t16 \
    @<(printf '%s\n%s\n' support_files/HG003/HG003.novaseq.pcr-free.40x.R1.fastq.gz support_files/HG003/HG003.novaseq.pcr-free.40x.R2.fastq.gz) \
    vg_output_pangenome/HG003/HG003 \
    vg_output_pangenome/tmp


#donwsample graph to 2 haplotypes for Giraffe
vg haplotypes -v 2 -t 16 \
    --include-reference \
    --diploid-sampling \
    -i /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.hapl \
    -k vg_output_pangenome/HG003/HG003.kff \
    -g vg_output_pangenome/HG003/HG003_diploid.gbz \
    /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz

#build mapping indexes (distance index, minimizer index, zipcodes) from the sample-specific graph
/private/home/yzybina/vg_1.74.1/vg autoindex \
    --prefix vg_output_pangenome/HG003/HG003 \
    --workflow giraffe \
    --no-guessing \
    -G vg_output_pangenome/HG003/HG003_diploid.gbz \
    --threads 16


#donwsample graph to 16 haplotypes for DeepVariant
vg haplotypes -v 2 -t 16 \
    --include-reference \
    --num-haplotypes 16 \
    -i /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.hapl \
    -k vg_output_pangenome/HG003/HG003.kff \
    -g vg_output_pangenome/HG003/HG003_16hap.gbz \
    /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz

# then back - convert the graph
vg gbwt --gbz-v1 -Z vg_output_pangenome/HG003/HG003_16hap.gbz -g vg_output_pangenome/HG003/HG003_16hap.v1.gbz