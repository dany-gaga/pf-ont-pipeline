#!/bin/bash
# =============================================================================
# 11_reads_to_ref.sh
# Map clean reads to the 3D7 reference genome (for Clair3 variant calling).
#
# This alignment is SEPARATE from the assembly-to-reference alignment
# used for Syri in step 14. They use different minimap2 presets:
#
#   map-ont (this step):  reads vs reference — for Clair3 pileup
#   asm5    (step 14):    assembly vs reference — for Syri SVs
#
# Clair3 requires read pileups at each position. Using the assembly-to-
# reference BAM (1 contig per position) gives 0 positions processed.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/01_filter/${SAMPLE}_pf_clean.fastq.gz
OUTPUT=${WORKDIR}/07_variants/reads_to_ref/reads_to_ref.bam

echo "=== Step 11: Read-to-reference alignment (for Clair3) ==="
echo "Sample:    ${SAMPLE}"
echo "Reads:     ${INPUT}"
echo "Reference: ${REF}"
echo "Preset:    map-ont"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    exit 1
fi

module load minimap2/2.28 samtools/1.19.2 2>/dev/null || \
    export PATH=${PIXI}:$PATH

minimap2 \
    -ax map-ont \
    -t ${THREADS} \
    ${REF} \
    ${INPUT} \
2> ${WORKDIR}/logs/11_reads_to_ref.log \
| samtools sort -@ ${THREADS} \
    -o ${OUTPUT}

samtools index ${OUTPUT}

echo ""
echo "=== Coverage summary ==="
samtools coverage ${OUTPUT} \
    | awk 'NR==1 || /^Pf3D7/' \
    | column -t

echo ""
echo "File: ${OUTPUT}"
echo "Step 11 complete."
