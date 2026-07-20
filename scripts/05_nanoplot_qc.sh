#!/bin/bash
# =============================================================================
# 05_nanoplot_qc.sh
# Generate read quality statistics and plots on clean reads.
# Run AFTER human depletion and Kraken filtering.
# Check output before proceeding to assembly:
#   - Median quality >= Q20 for R10.4.1 SUP
#   - Read N50 > 2000 bp
#   - Estimated Pf coverage = Total bases / 23000000
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/01_filter/${SAMPLE}_pf_clean.fastq.gz
OUTDIR=${WORKDIR}/02_qc/nanoplot

echo "=== Step 05: NanoPlot QC ==="
echo "Sample:  ${SAMPLE}"
echo "Input:   ${INPUT}"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    exit 1
fi

${PIXI}/NanoPlot \
    --fastq ${INPUT} \
    --outdir ${OUTDIR} \
    --threads ${THREADS} \
    --plots kde dot \
    --prefix ${SAMPLE}_ \
2> ${WORKDIR}/logs/05_nanoplot.log

echo ""
echo "=== Read statistics ==="
cat ${OUTDIR}/${SAMPLE}_NanoStats.txt

# Estimated Pf coverage
TOTAL_BASES=$(grep "Total bases" ${OUTDIR}/${SAMPLE}_NanoStats.txt \
    | awk '{gsub(",","",$NF); print $NF}')
COV=$(awk "BEGIN {printf \"%.1f\", ${TOTAL_BASES}/23000000}")
echo ""
echo "Estimated Pf coverage: ~${COV}x  (total bases / 23 Mb)"
echo "Step 05 complete."
