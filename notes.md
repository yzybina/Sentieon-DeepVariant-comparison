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
    vg_output/HG002.aligned.sorted.bam \
    > vg_output/HG002.aligned.sorted.renamed.bam
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
conda activate sentieon-cli-1.5.2

srun --cpus-per-task=1 --partition=medium --mem=50G --time=4:00:00 --pty bash

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