#!/bin/bash
set -euo pipefail

# ---- DeepVariant (your tool) ----
DV_QUERY=aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/query.vcf
DV_TRUTH=aardvark_results/vg_pangenomeDV_16hapmodel_filtered_WDLBAM/truth.vcf

# ---- other tool (e.g. Sentieon) — edit paths ----
OTHER_QUERY=aardvark_results/OTHER_TOOL_DIR/query.vcf
OTHER_TRUTH=aardvark_results/OTHER_TOOL_DIR/truth.vcf

DECISION_FIELD=BD

SIMPLE=support_files/grch38_simple_repeats.bed
SEGDUP=support_files/grch38_segmental_dups.bed
RMSK=support_files/grch38_repeat_masker.bed

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

extract() { bcftools view -i "FMT/${DECISION_FIELD}=\"${2}\"" "$1" -Ov -o "$3"; }

extract "$DV_QUERY"    FP "$TMPDIR/dv_fp.vcf"
extract "$OTHER_QUERY" FP "$TMPDIR/other_fp.vcf"
extract "$DV_TRUTH"    FN "$TMPDIR/dv_fn.vcf"
extract "$OTHER_TRUTH" FN "$TMPDIR/other_fn.vcf"

# DV errors NOT also made by the other tool = unique to DV
bedtools intersect -header -v -a "$TMPDIR/dv_fp.vcf" -b "$TMPDIR/other_fp.vcf" > "$TMPDIR/dv_fp_unique.vcf"
bedtools intersect -header -v -a "$TMPDIR/dv_fn.vcf" -b "$TMPDIR/other_fn.vcf" > "$TMPDIR/dv_fn_unique.vcf"

echo "DV FP total:        $(grep -vc '^#' "$TMPDIR/dv_fp.vcf")"
echo "DV FP unique to DV: $(grep -vc '^#' "$TMPDIR/dv_fp_unique.vcf")"
echo "DV FN total:        $(grep -vc '^#' "$TMPDIR/dv_fn.vcf")"
echo "DV FN unique to DV: $(grep -vc '^#' "$TMPDIR/dv_fn_unique.vcf")"

declare -A UNIQUE=( [FP]="$TMPDIR/dv_fp_unique.vcf" [FN]="$TMPDIR/dv_fn_unique.vcf" )

for LABEL in FP FN; do
  VCF="${UNIQUE[$LABEL]}"
  TOTAL=$(grep -vc '^#' "$VCF")
  SIMPLE_N=$(bedtools intersect -u -a "$VCF" -b "$SIMPLE"  | wc -l)
  SEGDUP_N=$(bedtools intersect -u -a "$VCF" -b "$SEGDUP"  | wc -l)
  RMSK_N=$(bedtools intersect -u -a "$VCF" -b "$RMSK"      | wc -l)
  OUTSIDE_N=$(bedtools intersect -v -a "$VCF" -b "$SIMPLE" "$SEGDUP" "$RMSK" | wc -l)
  echo "${LABEL} (unique to DV): total=$TOTAL simple_repeats=$SIMPLE_N segdups=$SEGDUP_N repeatmasker=$RMSK_N outside_all=$OUTSIDE_N"
done