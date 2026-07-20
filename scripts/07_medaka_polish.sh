#!/bin/bash
# =============================================================================
# 07_medaka_polish.sh
# Polish the Flye draft assembly using Medaka.
#
# Two sub-steps:
#   7a: Map clean reads back to the draft assembly (minimap2 map-ont)
#   7b: Run Medaka inference + sequence to produce polished FASTA
#
# IMPORTANT — Medaka API changed in v6+:
#   OLD (v5 and below): medaka consensus + medaka stitch
#   NEW (v6+):          medaka inference + medaka sequence
#
# Model must match basecaller chemistry:
#   SUP (Runs 1-3): r1041_e82_400bps_sup_v4.3.0
#   HAC (Run 4):    r1041_e82_400bps_hac_v5.2.0
#
# --cpu flag required on CPU-only nodes (no GPU available)
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

DRAFT=${WORKDIR}/03_assembly/flye/assembly.fasta
READS=${WORKDIR}/01_filter/${SAMPLE}_pf_clean.fastq.gz
BAM=${WORKDIR}/04_polish/medaka/reads_to_draft.bam
HDF=${WORKDIR}/04_polish/medaka/consensus.hdf
OUTPUT=${WORKDIR}/04_polish/medaka/consensus.fasta

echo "=== Step 07: Medaka polishing ==="
echo "Sample:  ${SAMPLE}"
echo "Draft:   ${DRAFT}"
echo "Model:   ${MEDAKA_MODEL}"

if [[ ! -f ${DRAFT} ]]; then
    echo "ERROR: Draft assembly not found: ${DRAFT}" >&2
    exit 1
fi

# ── Step 7a: Map reads to draft ──────────────────────────────────────────────
echo ""
echo "--- 7a: Mapping reads to draft assembly ---"

minimap2 \
    -a -x map-ont \
    -t ${THREADS} \
    ${DRAFT} \
    ${READS} \
2> ${WORKDIR}/logs/07a_medaka_minimap2.log \
| ${PIXI}/samtools sort -@ ${THREADS} \
    -o ${BAM}

${PIXI}/samtools index ${BAM}

MAPPED=$(${PIXI}/samtools view -c -F 4 ${BAM})
echo "Mapped reads: ${MAPPED}"

# ── Step 7b: Medaka inference ────────────────────────────────────────────────
echo ""
echo "--- 7b: Medaka inference (BAM -> HDF) ---"

${PIXI}/medaka inference \
    ${BAM} \
    ${HDF} \
    --model ${MEDAKA_MODEL} \
    --threads ${THREADS} \
    --cpu \
2> ${WORKDIR}/logs/07b_medaka_inference.log

# ── Step 7c: Medaka sequence (HDF -> polished FASTA) ────────────────────────
echo ""
echo "--- 7c: Medaka sequence (HDF -> polished FASTA) ---"

${PIXI}/medaka sequence \
    ${HDF} \
    ${DRAFT} \
    ${OUTPUT} \
    --threads ${THREADS} \
2> ${WORKDIR}/logs/07c_medaka_sequence.log

echo ""
echo "=== Result ==="
echo "Polished contigs: $(grep -c '>' ${OUTPUT})"
echo "File: ${OUTPUT}"
echo "Step 07 complete."
