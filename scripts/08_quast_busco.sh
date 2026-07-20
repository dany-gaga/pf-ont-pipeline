#!/bin/bash
# =============================================================================
# 08_quast_busco.sh
# Assembly quality assessment.
#
# QUAST: compares assembly to 3D7 reference
#   Key metrics: N50, genome fraction, mismatches, indels per 100 kbp
#
# BUSCO: checks gene content completeness
#   Uses apicomplexa_odb12.2 (renamed from odb10 in BUSCO v6)
#   Target: C > 80%, M < 10%
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

ASSEMBLY=${WORKDIR}/04_polish/medaka/consensus.fasta

echo "=== Step 08: QUAST + BUSCO quality assessment ==="
echo "Sample:    ${SAMPLE}"
echo "Assembly:  ${ASSEMBLY}"

if [[ ! -f ${ASSEMBLY} ]]; then
    echo "ERROR: Assembly not found: ${ASSEMBLY}" >&2
    exit 1
fi

# ── QUAST ────────────────────────────────────────────────────────────────────
echo ""
echo "--- QUAST ---"

${PIXI}/quast.py \
    ${ASSEMBLY} \
    --reference ${REF} \
    --features ${REF_GFF} \
    --eukaryote \
    --large \
    --threads ${THREADS} \
    --output-dir ${WORKDIR}/05_qc_asm/quast \
2> ${WORKDIR}/logs/08_quast.log

echo ""
echo "=== QUAST key metrics ==="
grep -E "Total length|# contigs|N50|Genome fraction|Mismatches per|Indels per" \
    ${WORKDIR}/05_qc_asm/quast/report.txt 2>/dev/null \
    | head -20

# ── BUSCO ────────────────────────────────────────────────────────────────────
echo ""
echo "--- BUSCO ---"

${PIXI}/busco \
    --in ${ASSEMBLY} \
    --out busco_result \
    --out_path ${WORKDIR}/05_qc_asm/busco \
    --mode genome \
    --lineage_dataset apicomplexa_odb12.2 \
    --cpu ${THREADS} \
    --force \
    --download_path ${WORKDIR}/05_qc_asm/busco/downloads \
2>&1 | tee ${WORKDIR}/logs/08_busco.log | grep -E "C:|Results:|BUSCO"

echo ""
echo "Full BUSCO summary:"
find ${WORKDIR}/05_qc_asm/busco -name "short_summary*.txt" -exec cat {} \;

echo ""
echo "Step 08 complete."
