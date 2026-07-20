#!/bin/bash
# =============================================================================
# 02_nanofilt.sh
# Filter reads by quality score and minimum length.
# Thresholds are per-run — set in 00_setup_variables.sh.
#
# Thresholds by run:
#   Run 1+2 (N50 ~763bp):   Q=12, len=500
#   Run 3   (N50 ~5635bp):  Q=15, len=1000
#   Run 4   (N50 ~10118bp): Q=15, len=2000
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/00_convert/${SAMPLE}_raw.fastq.gz
OUTPUT=${WORKDIR}/01_filter/${SAMPLE}_filtered.fastq.gz

echo "=== Step 02: NanoFilt read filtering ==="
echo "Sample:    ${SAMPLE}"
echo "Input:     ${INPUT}"
echo "Quality:   >= Q${NANOFILT_Q}"
echo "Length:    >= ${NANOFILT_LEN} bp"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    echo "Run 01_convert_to_fastq.sh first." >&2
    exit 1
fi

BEFORE=$(zcat ${INPUT} | awk 'NR%4==1' | wc -l)

gunzip -c ${INPUT} \
    | ${PIXI}/NanoFilt \
        --quality ${NANOFILT_Q} \
        --length  ${NANOFILT_LEN} \
    2> ${WORKDIR}/logs/02_nanofilt.log \
    | ${PIXI}/pigz -p ${THREADS} \
        > ${OUTPUT}

AFTER=$(zcat ${OUTPUT} | awk 'NR%4==1' | wc -l)
REMOVED=$((BEFORE - AFTER))
PCT=$(awk "BEGIN {printf \"%.1f\", ${AFTER}/${BEFORE}*100}")

echo ""
echo "=== Result ==="
echo "Before:   ${BEFORE} reads"
echo "After:    ${AFTER} reads (${PCT}% retained)"
echo "Removed:  ${REMOVED} reads"
echo "File:     ${OUTPUT}"
echo "Step 02 complete."
