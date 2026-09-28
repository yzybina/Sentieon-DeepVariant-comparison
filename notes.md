# get the most up-to date vg:
```
mkdir -p /private/home/yzybina/vg_1.76.1
cd /private/home/yzybina/vg_1.76.1
wget https://github.com/vgteam/vg/releases/download/v1.76.1/vg
chmod +x vg
./vg version
```


Renaming headers in bam file:
# Step 1: Generate the rename mapping (GRCh38#0#chr1 -> chr1)
```
samtools view -H vg_output/HG002.aligned.sorted.bam | grep "^@SQ" | \
    sed 's/.*SN:\([^\t]*\).*/\1/' | \
    awk '{new=$1; gsub(/^.*#[0-9]*#/, "", new); print $1"\t"new}' \
    > vg_output/contig_rename.txt
```

# Verify the mapping looks right
`head -5 vg_output/contig_rename.txt`

# Step 2: Rename contigs in the BAM
```
samtools reheader \
    --no-PG \
    -c 'perl -pe "s/(?<=\tSN:)(GRCh38#0#)//g"' \
    vg_output_pangenome/HG002.aligned.sorted.bam \
    > vg_output_pangenome/HG002.aligned.sorted.renamed.bam
```
# Step 3: Index the renamed BAM
`samtools index vg_output/HG002.aligned.sorted.renamed.bam`

## check number of records:
Sentieon:
```
bcftools stats /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome.vcf.gz | grep "number of records"
```
[W::bcf_hdr_check_sanity] LPL should be declared as Number=LG
[W::bcf_hdr_check_sanity] LAD should be declared as Number=LR
## number of records   .. number of data rows in the VCF
SN      0       number of records:      6,631,557

VG:
```
bcftools stats /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.output.vcf.gz | grep "number of records"
```
##  number of records   .. number of data rows in the VCF
SN      0       number of records:      7,655,763

truth set:
```
bcftools stats /private/groups/patenlab/yulia/sentieon_benchmarking/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz | grep "number of records"
```
##  number of records   .. number of data rows in the VCF
SN      0       number of records:      5,945,525


# 5/6/26
I used the wrong reference graph for calling variants: the full hprc-v2.1-mc-grch38.gbz that already has HG002 in it.
The hprc-v2.1-mc-grch38-eval.gbz may not have the sample. To test:
```
source ~/.bashrc
vg paths -x /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.d46.gbz -M | awk 'NR>1 {print $3}' | sort -u
```
check the number of haplotype paths in each graph:
```
vg gbwt -Z /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.d46.gbz -H
```
458
```
vg gbwt -Z /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz -H
```
also 458

-> eval does not have HG002

need to re-generate the .hapl file for the eval graph:

```

srun --cpus-per-task=1 --partition=medium --mem=50G --time=4:00:00 --pty bash
conda activate sentieon-cli-1.5.2

vg gbwt -Z /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output/HG002.gbz -H
```

just 4


# build the right version of vg:
```
git clone --recursive https://github.com/vgteam/vg.git
cd vg
make -j16
```

# back-convert the graph and check:
```
/private/home/yzybina/vg/bin/vg gbwt --gbz-v1 -Z vg_output/HG002.gbz -g vg_output/HG002.v1.gbz

/private/home/yzybina/vg/bin/vg gbwt -Z vg_output/HG002.v1.gbz -M
```
773 paths with names, 3 samples with names, 4 haplotypes, 195 contigs with names


vcf vs g.vcf: 
VCF (Variant Call Format) only records positions where a variant was detected — it's silent about the rest of the genome.gVCF (Genomic VCF) records every position in the genome — both variant sites and non-variant (reference) blocks — so you know whether a "missing" site was truly reference or just not covered.

# Aardvark github note: 
keep variants with no filter
```
bcftools view -f "PASS,." /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.vcf.gz -Oz -o /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz
```
Followed by:
```
bcftools index -t /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz
```

# Check quality of vcf calls:
```
bcftools query -f '%FILTER\n' /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.output.pangenome.vcf.gz | sort | uniq -c
```
1087010 NoCall
4802169 PASS
2429515 RefCall

# filter VGDV results:
```
bcftools view -f "PASS,." /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.output.pangenome.vcf.gz -Oz -o /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz

bcftools index -t /private/groups/patenlab/yulia/sentieon_benchmarking/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz
```

Run hap.py to comare its results to aardvark:

```
docker run -it \
    -v /private/groups/patenlab/yulia/sentieon_benchmarking:/data \
    -v $(pwd):/output \
    pkrusche/hap.py /opt/hap.py/bin/hap.py \
    /data/truthsets/HG002_GRCh38_v5.0q_smvar.vcf.gz \
    /data/Sentieon_output/HG002_pangenome_2.1_evalgraph.filtered.vcf.gz \
    -f /data/truthsets/HG002_GRCh38_v5.0q_smvar.benchmark.bed \
    -o /output/happy_results/sentieon_2.1 \
    -r /data/support_files/hg38_ucsc.fa
```

# Re-run DeepVariant using 16 haplotypes model
The first run onlu used --model_type WGS flag
Per Mobin's suggestion I downloaded the 16 haplotypes model files into /support_files/dv_16hapl_model
Added into the script:
MODEL_CKPT="/data/support_files/dv_16hapl_model/checkpoint-153600-0.98945-1"
and to the docker command: --customized_model "${MODEL_CKPT}"

job 34304641 - completed 07:24:17hrs Memory Utilized: 9.18 MB
Filtering to PASS:

```
bcftools view -f "PASS,." vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.vcf.gz -Oz -o vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.filtered.vcf.gz

bcftools index -t vg_output_pangenome/16hap_model/HG002_eval.output.pangenome.filtered.vcf.gz
```

Then re-running aardvark on this dataset (job 34414279)

# analyze the resulting vcf file:
`bcftools view aardvark_results/sentieon_2.1_evalgraph_filtered/query.vcf.gz `

example of a line is:
#CHROM	POS	           ID	  REF	     ALT	QUAL	FILTER	INFO	FORMAT	         default
chr1    107249159       .       C       CAATAAT .       .       .       GT:BD:EA:OA:RI  1/1:TP:2:2:139196

| Column | Value | Meaning |
|--------|-------|---------|
| CHROM | chr1 | Chromosome 1 |
| POS | 107249159 | Position of the reference anchor base (the C) |
| ID | . | No rsID or name assigned |
| REF | C | Reference allele — a single cytosine |
| ALT | CAATAAT | Alternate allele — C followed by an insertion of AATAAT (6 bp insertion) |
| QUAL | . | No quality score provided |
| FILTER | . | No filter applied (not PASS, not flagged) |
| INFO | . | No INFO annotations |
| FORMAT | GT:BD:EA:OA:RI | Keys for the sample column |

| Key | Value | Meaning |
|-----|-------|---------|
| GT | 1/1 | Homozygous alternate — both copies carry the insertion |
| BD | TP | Benchmark Decision — True Positive; this call matched the truth set |
| EA | 2 | Edit distance / allele count on the evaluation side — often the number of allele matches found |
| OA | 2 | Other allele count — typically the corresponding truth-side allele count |
| RI | 139196 | Region index — an internal identifier for the confidence region this variant falls in |


I want to filter this file to include FP variants only:
```
#Sentieon file:
bcftools view -i 'FORMAT/BD="FP"' aardvark_results/sentieon_2.1_evalgraph_filtered/query.vcf.gz > aardvark_results/sentieon_2.1_evalgraph_filtered/fp_only.vcf.gz

#DV result (replace later with 16hap model)
bcftools view -i 'FORMAT/BD="FP"' aardvark_results/vg_pangenomeDV_filtered/query.vcf.gz > aardvark_results/vg_pangenomeDV_filtered/fp_only.vcf.gz

bcftools view -i 'FORMAT/BD="FP"' aardvark_results/vg_pangenomeDV_16hapmodel_filtered/query.vcf.gz > aardvark_results/vg_pangenomeDV_16hapmodel_filtered/fp_only.vcf.gz

```

I want to look at variants that Sentieon got as TP and DV got as FP - would not show up in the other file. 
Aadrvark results: more FPs in DV using the BASEPAIR comarison and (slightly) more FPs in Sentieon by Genotype comparison
The basepair score reconstructs the truth and query haplotype sequences and compares them base by base. It's variant-type agnostic, weights each modified basepair equally, and significantly reduces the representation biases inherent in genotype-based scoring.

Looking at the scatter plots of FP values (filtered vcfs) - sentieon stops correlating with DV at ~3K for SNP and ~10K for JointInDel. What are these regions?

Change vt and fp values as needed:
```
awk -F'\t' '
  NR==1 { for(i=1;i<=NF;i++) col[$i]=i; next }
  $col["comparison"]=="BASEPAIR" {
    vt = $col["variant_type"]
    fp = $col["query_fp"]
    if (vt=="Snv" && fp>3000)
      print $col["region_label"]
  }
' aardvark_results/vg_pangenomeDV_filtered/summary.tsv | sort -u
```

pull FP positions from labeled vcf into a bed file:
```
bcftools view -i 'FORMAT/BD[0]="FP"' aardvark_results/vg_pangenomeDV_16hapmodel_filtered/query.vcf.gz \
  | bcftools query -f '%CHROM\t%POS0\t%END\t%REF\t%ALT\n' \
  > aardvark_results/vg_pangenomeDV_16hapmodel_filtered/fp.bed
```

extract FP only regions from BAM:
```
samtools view -b -L aardvark_results/vg_pangenomeDV_16hapmodel_filtered/fp.bed \
    vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
    -o fp_regions.bam
samtools index fp_regions.bam
```

Extract FP variants unique to DV: subtract out FPs found by Sentieon:
```
bedtools intersect -a aardvark_results/vg_pangenomeDV_16hapmodel_filtered/fp_only.vcf.gz -b aardvark_results/sentieon_2.1_evalgraph_filtered/fp_only.vcf.gz -v -header > fp_unique_to_DV.vcf

```

# Experiment: run DeepVariant with the bam file produced by Sentieon:
```
bcftools view -f "PASS,." vg_output_pangenome/sentieonbam/HG002_eval.sentieonbam.vcf.gz -Oz -o vg_output_pangenome/sentieonbam/HG002_eval.sentieonbam.filtered.vcf.gz

bcftools index -t vg_output_pangenome/sentieonbam/HG002_eval.sentieonbam.filtered.vcf.gz

```

ABRA2 realignment and bamleft align. DV has realignment but this step may still prove helpful.
.fa file must have a .fai in the same dir
ABRA2 needs a target BED
It needs Java 8+ on the node, run: java -version to check
Installed in /private/home/yzybina/abra2-2.24.jar
The contig-name point is the one that'll bite you: ABRA2's --targets BED must use the same contig names as your BAM and your reference. Your BAM is the renamed one (chr1-style, since you did the GRCh38#0#chr1 → chr1 renaming earlier), so the BED must be chr1-style too. Mismatched names → ABRA2 silently realigns nothing or errors.

```
java -Xmx16G -jar /path/to/abra2.jar \
  --in HG002_eval.aligned.sorted.renamed.bam \
  --out HG002_eval.indel_realigned.bam \
  --ref /data/support_files/hg38_ucsc.fa \
  --targets targets.bed \
  --index \
  --threads 16
  ```

```
bamleftalign \
  --fasta-reference /data/support_files/hg38_ucsc.fa \
  --compressed \
  < HG002_eval.indel_realigned.bam \
  > HG002_eval.left_shifted.bam

samtools index -b HG002_eval.left_shifted.bam HG002_eval.left_shifted.bam.bai
```

Abra2 realignment and indel left shifting: the sh script ran into error with chromosome order:
```
#verify chr names
samtools view -H vg_output_pangenome/HG002_eval.aligned.sorted.bam | grep '^@SQ' | cut -f2 | head -50
cut -f1 support_files/hg38_ucsc.fa.fai | head -25


#reorder
picard ReorderSam \
  I=vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
  O=vg_output_pangenome/HG002.reordered.bam \
  REFERENCE=support_files/hg38_ucsc.fa

samtools index vg_output_pangenome/HG002.reordered.bam
samtools quickcheck vg_output_pangenome/HG002.reordered.bam && echo "reorder OK"
```

Creting Aardvark WDL, test wth toil:
```
#optional: clear previous run
toil clean file:/private/groups/patenlab/yulia/sentieon_benchmarking/aardvark_jobstore

export TOIL_SLURM_ARGS="--time=01:0:00 --partition=short"
export SINGULARITY_CACHEDIR="/data/tmp/$(whoami)/cache/singularity"
export MINIWDL__SINGULARITY__IMAGE_CACHE="/data/tmp/$(whoami)/cache/miniwdl"

toil-wdl-runner \
    --jobStore ./aardvark_jobstore \
    --batchSystem slurm \
    --caching false \
    --batchLogsDir ./logs \
    vg_wdl/workflows/aardvark_evaluation.wdl \
    aardvark_test.json \
    -o aardvark_run \
    -m aardvark_run.json
```


Run Giraffe WDL:
```
toil clean file:/private/groups/patenlab/yulia/sentieon_benchmarking/jobstore_giraffe

toil-wdl-runner \
  --jobstore ./jobstore_giraffe \
  --batchSystem slurm \
  --slurmPartition long \
  --slurmTime 30:00:00 \
  --wdlContainer singularity \
  vg_wdl/workflows/giraffe.wdl \
  giraffe_inputs.json \
  --wdlOutputDirectory ./giraffe_out \
  --wdlOutputFile giraffe_outputs.json
```

Then filter and index vcf:
```
bcftools view -f "PASS,." vg_output_pangenome/16hap_model_wdlbam/HG002_eval.output.pangenome.wdlbamvcf.gz -Oz -o vg_output_pangenome/16hap_model_wdlbam/HG002_eval.output.pangenome.wdlbamvcf.filtered.gz
```
Followed by:
```
bcftools index -t vg_output_pangenome/16hap_model_wdlbam/HG002_eval.output.pangenome.wdlbamvcf.filtered.gz
```

7.13.26 - some support files :.hapl, .kff, .min deleted to save space on cluster. Re-generate with autoindex.sh if needed


python3 find_tool_advantage.py \
  --favor-file sentieon_2.1graph_1.2model_filtered/summary.tsv \
  --vs-file vg_pangenomeDV_16hapmodel_filtered_WDLBAM/summary.tsv \
  --out sentieon_advantage.csv


# 8.3.26: work on visualizing graphs:
These 2 alone make the subgraph labeled with emojis for paths. but no reference coordinates:
```
/private/home/yzybina/vg_1.74.1/vg chunk -x /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz -p "GRCh38#0#chr2:241866272-241866375" -c 20 -O pg > region_subgraph.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn region_subgraph.vg | dot -Tsvg -o region_subgraph.svg

# make the same for full graph at that position:
/private/home/yzybina/vg_1.74.1/vg chunk -x /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz -p "GRCh38#0#chr2:241866272-241866375" -c 20 -O pg > region_subgraph_full.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn region_subgraph_full.vg | dot -Tsvg -o region_subgraph_full.svg

```

checking stats and path name sof my downsamples graph:
```
/private/home/yzybina/vg_1.74.1/vg stats -z region_subgraph.vg

/private/home/yzybina/vg_1.74.1/vg paths -L -x /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz

#check number of haplotypes in graph:
/private/home/yzybina/vg_1.74.1/vg gbwt -Z /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz -H <- the 4 here comes from metadata summary

/private/home/yzybina/vg_1.74.1/vg paths --metadata -x /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz > paths.tsv
```

# try with the 16 hap graph:
/private/home/yzybina/vg_1.74.1/vg chunk -x sentieon_benchmarking/vg_output_pangenome/HG002.16hap.gbz -p "GRCh38#0#chr2:241866272-241866375" -c 20 -O pg > region_subgraph16.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn region_subgraph16.vg | dot -Tsvg -o region_subgraph16.svg

# search BAM for my read names: 
samtools view -N readnames.txt /private/groups/patenlab/yulia/sentieon_benchmarking/giraffe_out/Giraffe.mergeBAM/HG002_merged.positionsorted.bam | awk -v OFS='\t' '{print $1,$2,$3,$4}'



export PATH="/private/home/yzybina/vg_1.74.1/vg:$PATH"

# re-analyzing variants in slides:

# 6:
All reads mapped to this region are low mapq. Extract readnames:
```
samtools view /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
  chr2:3187846-3187846 \
  | cut -f1 | sort -u > slide6/reads.txt

samtools view /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam chr2:3187846-3187846 \
  | awk 'BEGIN{OFS="\t"} {rn=($7=="=")?$3:$7; print $3, $4, $4+150; print rn, $8, $8+150}' \
  >> slide6/regions.bed

samtools view -b -L slide6/regions.bed -N slide6/reads.txt \
  /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
  | samtools sort -n - \
  | samtools fastq - | gzip > slide6/subset.fq.gz

# run giraffe remap

{
  echo -e "READ_NAME\tMATE\tTYPE\tCHROM\tPOS\tMAPQ\tSCORE"
  samtools view slide6/subset.multi.sorted.bam | gawk 'BEGIN{OFS="\t"}
  {
    as="NA"
    for(i=12;i<=NF;i++) if ($i ~ /^AS:i:/) { split($i,a,":"); as=a[3] }
    type = (and($2,256)) ? "secondary" : "primary"
    mate = and($2,64) ? "/1" : (and($2,128) ? "/2" : "?")
    print $1, mate, type, $3, $4, $5, as
  }'
} > slide6/mappings_table.tsv

{ head -1 slide6/mappings_table.tsv; tail -n +2 slide6/mappings_table.tsv | sort -k1,1 -k2,2 -k7,7nr; } > slide6/mappings_table_sorted.tsv
mv slide6/mappings_table_sorted.tsv slide6/mappings_table.tsv

column -t slide6/mappings_table.tsv

```

# #7: 
All reads mapped to this region are low mapq. Extract readnames:
```
#starting over - scanning fastq is too slow. From BAM, get out reads at that position, get their name, then find mate. Generate bed with positions for each read and its mate
samtools view /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam chr1:109681058-109681058 \
  | awk 'BEGIN{OFS="\t"} {rn=($7=="=")?$3:$7; print $3, $4, $4+150; print rn, $8, $8+150}' \
  >> slide7/regions.bed

# then
samtools view -b -L slide7/regions.bed -N slide7/reads.txt \
  /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.renamed.bam \
  | samtools sort -n - \
  | samtools fastq - | gzip > slide7/subset.fq.gz


# now run giraffe with gam output on these in sh

Job Wall-clock time: 00:03:56
Memory Utilized: 49.05 GB
Memory Efficiency: 49.05% of 100.00 GB

{
  echo -e "READ_NAME\tMATE\tTYPE\tCHROM\tPOS\tMAPQ\tSCORE"
  samtools view slide7/subset.multi.sorted.bam | gawk 'BEGIN{OFS="\t"}
  {
    as="NA"
    for(i=12;i<=NF;i++) if ($i ~ /^AS:i:/) { split($i,a,":"); as=a[3] }
    type = (and($2,256)) ? "secondary" : "primary"
    mate = and($2,64) ? "/1" : (and($2,128) ? "/2" : "?")
    print $1, mate, type, $3, $4, $5, as
  }'
} > slide7/mappings_table.tsv

{ head -1 slide7/mappings_table.tsv; tail -n +2 slide7/mappings_table.tsv | sort -k1,1 -k2,2 -k7,7nr; } > slide7/mappings_table_sorted.tsv
mv slide7/mappings_table_sorted.tsv slide7/mappings_table.tsv

column -t slide7/mappings_table.tsv
```
# #8:
```
Slide 8: 17 bp deletion, checking alignment. Waiting for GAM file to sort so I can visualize

# See structure of full graph, not eval. Is the path making up HG002 truth set there?

/private/home/yzybina/vg_1.74.1/vg chunk -x /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38/hprc-v2.1-mc-grch38.gbz -p "GRCh38#0#chr2:241866272-241866375" -c 20 -O pg > slide8/region_subgraph_fullnoteval.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn slide8/region_subgraph_fullnoteval.vg | dot -Tsvg -o slide8/region_subgraph_fullnoteval.svg

# experiment with visualizing alignments through GAM:
vg find -x /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz -l /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.gam -o "106220722:106220828" > slide8/candidate_reads.gam
echo $?

/private/home/yzybina/vg_1.74.1/vg view -aj slide8/candidate_reads.gam | head -c 500
/private/home/yzybina/vg_1.74.1/vg view -dpn region_subgraph.vg -A slide8/candidate_reads.gam -m | dot -Tsvg -o slide8/aln.svg

grep -F -f readnames.txt <(vg view -aj /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002_eval.aligned.sorted.gam) \
  | jq -r '"\(.name)\t\(.path.mapping[0].position.node_id)"' \
  > reads.tsv

/private/home/yzybina/vg_1.74.1/vg view -aj slide8/candidate_reads.gam | head -c 500

```

# #11
```
# need to visualize the graph at this pos:

/private/home/yzybina/vg_1.74.1/vg chunk -x /private/groups/patenlab/yulia/sentieon_benchmarking/vg_output_pangenome/HG002.gbz -p "GRCh38#0#chr8:61813776-61813815" -c 20 -O pg > slide11/region_subgraph.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn slide11/region_subgraph.vg | dot -Tsvg -o slide11/region_subgraph.svg

and look at full graph (eval) at this pos:
/private/home/yzybina/vg_1.74.1/vg chunk -x /private/groups/cgl/hprc-graphs/hprc-v2.1-dec23/hprc-v2.1-mc-grch38-eval/hprc-v2.1-mc-grch38-eval.gbz -p "GRCh38#0#chr8:61813776-61813815" -c 20 -O pg > slide11/region_subgraph_full.vg

/private/home/yzybina/vg_1.74.1/vg view -dpn slide11/region_subgraph_full.vg | dot -Tsvg -o slide11/region_subgraph_full.svg

```
# Running Kishwar's vcf through Aardvark:
```
bcftools view -f "PASS,." Kishwar_vcf/hg002_wgs_dv/HG002-year2-hprc_v2.1-hap32-exp_dbg_HG002.deepvariant.vcf.gz -Oz -o Kishwar_vcf/hg002_wgs_dv/HG002-year2-hprc_v2.1-hap32-exp_dbg_HG002.deepvariant.filtered.vcf.gz

bcftools index -t Kishwar_vcf/hg002_wgs_dv/HG002-year2-hprc_v2.1-hap32-exp_dbg_HG002.deepvariant.filtered.vcf.gz
```

# Continuing with analysis:

Question:  what is the call quality range of TP variants in the DV16hap_model_WDLBAM vcf?
```
#!/usr/bin/env bash
set -euo pipefail

QUERY_VCF="aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/query.vcf"
ORIG_VCF="vg_output_pangenome/16hap_model_wdlbam/HG002_eval.output.pangenome.wdlbam.filtered.vcf"

awk 'BEGIN{FS=OFS="\t"}
     NR==FNR {tp[$1 SUBSEP $2 SUBSEP $3 SUBSEP $4]=1; next}
     (($1 SUBSEP $2 SUBSEP $3 SUBSEP $4) in tp) && $5!="." {print $5}' \
     <(bcftools query -i 'FORMAT/BD="TP"' -f '%CHROM\t%POS\t%REF\t%ALT\n' "$QUERY_VCF") \
     <(bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\n' "$ORIG_VCF") \
  | sort -n \
  | awk '{a[NR]=$1; sum+=$1}
         END{
           n=NR
           if(n==0){print "no matched TP calls with QUAL"; exit}
           printf "n=%d\nmin=%s\nmax=%s\nmean=%.3f\nmedian=%s\n",
             n, a[1], a[n], sum/n, (n%2 ? a[(n+1)/2] : (a[n/2]+a[n/2+1])/2)
         }'
```
Results in:
n=4391123
min=3
max=26
mean=24.277
median=24.7

pull out some TPs with quals <5:
```
set +o pipefail
set +e

awk 'BEGIN{FS=OFS="\t"}
     NR==FNR {tp[$1 SUBSEP $2 SUBSEP $3 SUBSEP $4]=1; next}
     (($1 SUBSEP $2 SUBSEP $3 SUBSEP $4) in tp) && $5!="." && $5+0<5 {print $1, $2, $3, $4, $5}' \
     <(bcftools query -i 'FORMAT/BD="TP"' -f '%CHROM\t%POS\t%REF\t%ALT\n' "$QUERY_VCF") \
     <(bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\n' "$ORIG_VCF") \
  | sort -k5,5n \
  | head -n 10
```
chr10   108776806       T       TTATATATATATATATATATATATATATATATATA     3 <- this one Sentieon got FN
chr10   13221530        C       CATATAT 3 <- of 41 reads, 5 show 6bp ins, 8show 12 bp ins. High MAPQ reads. Both tools got right. Repeat masked region
chr11   64444240        TTTTC   T       3 <- Repeat masked region, Sentieon got FN. High MAPQ reads, HET del, 21/43 reads have 4bp del
chr11   86109786        T       C       3 <- Repeat masked region, Sention got FN, DV got TP despite T : 12 (92%, 0+, 12- )C : 1 (8%, 0+, 1- ), MAPQ60
chr12   131652624       T       A       3 <- Repeat masked region, Sention got FN, DV got right despite all alt supporting reads being MAPQ 1
chr12   33106596        A       G       3 <- Repeat masked region, both tools got right. Reads supporting alt are MAPQ 1
chr13   31017026        C       T       3 <- Repeat masked region, Sention got FN, avg MAPQ 47
chr14   56447386        T       A       3 <- Repeat masked region, both tools got right. DV got right despite all alt supporting reads being MAPQ 1
chr16   18227345        G       T       3 <- Segmental dup region, both tools got right. DV got right despite all alt supporting reads being MAPQ 1
chr17   81970169        A       ACACG   3 <- Simple repeat region, Sentieon got FN. DV got right despite none of the reads showing insertion. Avg MAPQ 57.6



What is the average MAPQ at this position?
```
chr17:81970169
samtools view WDL_giraffe/Giraffe.mergeBAM/HG002_merged.positionsorted.bam chr17:81970169-81970169 | awk '{sum+=$5; n++} END {print "mean MAPQ:", sum/n, "n=" n}'
```

Make variant density plots:
```
#FP:
bcftools view -e 'FMT/BD="TP"' aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/query.vcf.gz | vcftools --vcf - --SNPdensity 1000000 --out plots/densityFP

#FN:
bcftools view -e 'FMT/BD="TP"' aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/truth.vcf.gz | vcftools --vcf - --SNPdensity 1000000 --out plots/densityFN

python3 plots/plot_density.py plots/densityFP.snpden plots/density_FP_heatmap.png support_files/centromeres_hg38.tsv
python3 plots/plot_density.py plots/densityFN.snpden plots/density_FN_heatmap.png support_files/centromeres_hg38.tsv
```

Question:  what is the call quality range of FP variants in the DV16hap_model_WDLBAM vcf?
```
#!/usr/bin/env bash
set -euo pipefail

QUERY_VCF="aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/query.vcf"
ORIG_VCF="vg_output_pangenome/16hap_model_wdlbam/HG002_eval.output.pangenome.wdlbam.filtered.vcf"

awk 'BEGIN{FS=OFS="\t"}
     NR==FNR {tp[$1 SUBSEP $2 SUBSEP $3 SUBSEP $4]=1; next}
     (($1 SUBSEP $2 SUBSEP $3 SUBSEP $4) in tp) && $5!="." {print $5}' \
     <(bcftools query -i 'FORMAT/BD="FP"' -f '%CHROM\t%POS\t%REF\t%ALT\n' "$QUERY_VCF") \
     <(bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\n' "$ORIG_VCF") \
  | sort -n \
  | awk '{a[NR]=$1; sum+=$1}
         END{
           n=NR
           if(n==0){print "no matched FP calls with QUAL"; exit}
           printf "n=%d\nmin=%s\nmax=%s\nmean=%.3f\nmedian=%s\n",
             n, a[1], a[n], sum/n, (n%2 ? a[(n+1)/2] : (a[n/2]+a[n/2+1])/2)
         }'
```

Find variant counts inside each of the bed regions (simple repeats, segmental dups, repatmasked) and outside any of those (but still in truth hugh confidence)

scripts/bed_vcf_intersect.sh

Result:
FP: total=12972 simple_repeats=7167 segdups=2289 repeatmasker=9636 outside_all=1310
FN: total=52259 simple_repeats=25771 segdups=11022 repeatmasker=38806 outside_all=5512


Generate stacked bar charts:
```
python plots/stacked_bars.py \
  --input aardvark_results/sentieon_2.1graph_1.2model_filtered/summary.tsv:Sentieon:HG002 \
  --input aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/summary.tsv:DeepVariant:HG002 \
  --input aardvark_results/sentieon_HG003/summary.tsv:Sentieon:HG003 \
  --input aardvark_results/DV_HG003/summary.tsv:DeepVariant:HG003 \
  -o plots/error_counts.png
```