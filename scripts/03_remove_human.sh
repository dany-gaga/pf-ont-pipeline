#!/bin/bash
# =============================================================================
# 03_remove_human.sh
# Remove human reads using negative filtering against hg38.
#
# Strategy: map to hg38, keep only UNMAPPED reads (-f 4).
# This preserves divergent Pf reads (var/rifin/stevor alleles that differ
# from 3D7) that would be lost if we instead mapped to the Pf reference.
#
# P. falciparum cultures contain ~93% human DNA from red blood cells.
# Without this step, Flye assembles ~915 Mb of mixed human/Pf sequence.
# With this step: ~23.9 Mb clean Pf assembly.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/01_filter/${SAMPLE}_filtered.fastq.gz
BAM_TMP=${WORKDIR}/01_filter/${SAMPLE}_human_mapping.bam
OUTPUT=${WORKDIR}/01_filter/${SAMPLE}_non_human.fastq.gz

echo "=== Step 03: Human read depletion ==="
echo "Sample:    ${SAMPLE}"
echo "Input:     ${INPUT}"
echo "hg38 MMI:  ${HG38_MMI}"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    exit 1
fi
if [[ ! -f ${HG38_MMI} ]]; then
    echo "ERROR: hg38 minimap2 index not found: ${HG38_MMI}" >&2
    echo "Run setup/download_databases.sh first." >&2
    exit 1
fi

export PATH=${PIXI}:$PATH

BEFORE=$(zcat ${INPUT} | awk 'NR%4==1' | wc -l)

# Map to hg38
minimap2 \
    -ax map-ont \
    -t ${THREADS} \
    ${HG38_MMI} \
    ${INPUT} \
2> ${WORKDIR}/logs/03_human_minimap2.log \
| ${PIXI}/samtools sort -@ ${THREADS} \
    -o ${BAM_TMP}

${PIXI}/samtools index ${BAM_TMP}

# Keep only unmapped reads (-f 4 = keep unmapped flag)
${PIXI}/samtools fastq \
    -@ ${THREADS} \
    -f 4 \
    ${BAM_TMP} \
2>> ${WORKDIR}/logs/03_human_minimap2.log \
| ${PIXI}/pigz -p ${THREADS} \
    > ${OUTPUT}

# Clean up large BAM
rm -f ${BAM_TMP} ${BAM_TMP}.bai

AFTER=$(zcat ${OUTPUT} | awk 'NR%4==1' | wc -l)
HUMAN=$((BEFORE - AFTER))
PCT_HUMAN=$(awk "BEGIN {printf \"%.1f\", ${HUMAN}/${BEFORE}*100}")
PCT_KEPT=$(awk "BEGIN {printf \"%.1f\", ${AFTER}/${BEFORE}*100}")

echo ""
echo "=== Result ==="
echo "Before:       ${BEFORE} reads"
echo "Human reads:  ${HUMAN} (${PCT_HUMAN}%)"
echo "Non-human:    ${AFTER} (${PCT_KEPT}% retained)"
echo "File:         ${OUTPUT}"
echo "Step 03 complete."
