#!/bin/bash
# =============================================================================
# 06_flye_assembly.sh
# De novo genome assembly using Flye.
#
# Input: clean reads (human-depleted, Kraken-filtered)
# Output: draft assembly FASTA + assembly_info.txt
#
# CRITICAL: export PATH before running — Flye calls minimap2 internally
# as a subprocess. Using full path to Flye alone is not sufficient.
#
# Expected output (at ~12-20x Pf coverage):
#   ~79 contigs, ~23.9 Mb total, N50 ~1.4 Mb
#   contig_96: mitochondria (circular, ~45 kb, very high coverage)
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/01_filter/${SAMPLE}_pf_clean.fastq.gz
OUTDIR=${WORKDIR}/03_assembly/flye

echo "=== Step 06: Flye de novo assembly ==="
echo "Sample:   ${SAMPLE}"
echo "Input:    ${INPUT}"
echo "Output:   ${OUTDIR}"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    exit 1
fi

# CRITICAL: Flye calls minimap2 as an internal subprocess
export PATH=${PIXI}:$PATH

${PIXI}/flye \
    --nano-hq ${INPUT} \
    --genome-size 23m \
    --out-dir ${OUTDIR} \
    --threads ${THREADS} \
2> ${WORKDIR}/logs/06_flye.log

if [[ ! -f ${OUTDIR}/assembly.fasta ]]; then
    echo "ERROR: Assembly failed. Check logs/06_flye.log" >&2
    exit 1
fi

echo ""
echo "=== Assembly statistics ==="
echo "Contigs: $(grep -c '>' ${OUTDIR}/assembly.fasta)"
echo ""
echo "assembly_info.txt:"
cat ${OUTDIR}/assembly_info.txt

echo ""
echo "Step 06 complete."
echo "Output: ${OUTDIR}/assembly.fasta"
