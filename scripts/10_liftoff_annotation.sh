#!/bin/bash
# =============================================================================
# 10_liftoff_annotation.sh
# Project PlasmoDB-68 gene annotations onto the new assembly using Liftoff.
#
# Projects 5,318 protein_coding_gene features from 3D7 coordinate space
# onto the sample-specific assembly coordinates.
#
# IMPORTANT: The -f flag requires a FILE containing feature types,
# NOT the feature type name directly:
#   WRONG:   liftoff -f protein_coding_gene ...
#   CORRECT: echo "protein_coding_gene" > features.txt
#            liftoff -f features.txt ...
#
# Unmapped genes: mostly VAR/RIF/STEVOR subtelomeric antigen genes.
# These are expected to differ between field isolates and 3D7.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

ASSEMBLY=${WORKDIR}/04_polish/medaka/consensus.fasta
FEATURES_FILE=${WORKDIR}/06_annotation/features_to_lift.txt
OUTPUT_GFF=${WORKDIR}/06_annotation/${SAMPLE}_liftoff.gff3
UNMAPPED=${WORKDIR}/06_annotation/${SAMPLE}_unmapped.txt
TMPDIR=${WORKDIR}/06_annotation/liftoff_tmp

echo "=== Step 10: Liftoff annotation projection ==="
echo "Sample:    ${SAMPLE}"
echo "Assembly:  ${ASSEMBLY}"
echo "GFF:       ${REF_GFF}"

if [[ ! -f ${ASSEMBLY} ]]; then
    echo "ERROR: Assembly not found: ${ASSEMBLY}" >&2
    exit 1
fi

# Create features file (required — -f flag expects a file)
echo "protein_coding_gene" > ${FEATURES_FILE}

${PIXI}/liftoff \
    -g ${REF_GFF} \
    -o ${OUTPUT_GFF} \
    -u ${UNMAPPED} \
    -dir ${TMPDIR} \
    -f ${FEATURES_FILE} \
    -p ${THREADS} \
    ${ASSEMBLY} \
    ${REF} \
2> ${WORKDIR}/logs/10_liftoff.log

echo ""
echo "=== Result ==="
MAPPED=$(grep -c "protein_coding_gene" ${OUTPUT_GFF} 2>/dev/null || echo 0)
UNMAPPED_N=$(wc -l < ${UNMAPPED})
echo "Genes mapped:    ${MAPPED}"
echo "Genes unmapped:  ${UNMAPPED_N}"
echo "GFF3 output:     ${OUTPUT_GFF}"
echo ""
echo "First 5 unmapped genes:"
head -5 ${UNMAPPED}

echo ""
echo "Step 10 complete."
