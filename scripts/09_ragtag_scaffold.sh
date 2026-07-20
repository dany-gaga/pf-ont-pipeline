#!/bin/bash
# =============================================================================
# 09_ragtag_scaffold.sh
# Reference-guided scaffolding using RagTag.
#
# Orders and orients assembly contigs into chromosome-scale pseudomolecules
# using the 3D7 reference as a guide. Produces two output FASTAs:
#
#   ragtag.scaffold.fasta     - all sequences (chromosomes + unplaced contigs)
#   ragtag.chromosomes.fasta  - 16 chromosome-scale sequences only,
#                               with _RagTag suffix removed (required for Syri)
#
# Required for:
#   - Syri structural variant detection (needs 1-to-1 chromosome matching)
#   - Genome database submission (NCBI/ENA expect chromosome-scale assembly)
#
# Unplaced contigs (-u flag) are kept in ragtag.scaffold.fasta —
# these represent strain-specific sequences absent from 3D7.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

ASSEMBLY=${WORKDIR}/04_polish/medaka/consensus.fasta
OUTDIR=${WORKDIR}/04_scaffold

echo "=== Step 09: RagTag scaffolding ==="
echo "Sample:    ${SAMPLE}"
echo "Assembly:  ${ASSEMBLY}"

if [[ ! -f ${ASSEMBLY} ]]; then
    echo "ERROR: Assembly not found: ${ASSEMBLY}" >&2
    exit 1
fi

export PATH=${PIXI}:$PATH

# ── Step 9a: Scaffold ─────────────────────────────────────────────────────────
${PIXI}/ragtag.py scaffold \
    ${REF} \
    ${ASSEMBLY} \
    -o ${OUTDIR} \
    -t ${THREADS} \
    -u \
2> ${WORKDIR}/logs/09_ragtag.log

echo ""
echo "=== Scaffolding statistics ==="
cat ${OUTDIR}/ragtag.scaffold.stats

# ── Step 9b: Extract chromosomes with clean names ─────────────────────────────
echo ""
echo "--- Extracting chromosome-scale sequences ---"

python3 << EOF
from Bio import SeqIO
import sys

ref_chrs = {
    "Pf3D7_01_v3","Pf3D7_02_v3","Pf3D7_03_v3","Pf3D7_04_v3",
    "Pf3D7_05_v3","Pf3D7_06_v3","Pf3D7_07_v3","Pf3D7_08_v3",
    "Pf3D7_09_v3","Pf3D7_10_v3","Pf3D7_11_v3","Pf3D7_12_v3",
    "Pf3D7_13_v3","Pf3D7_14_v3","Pf3D7_API_v3","Pf3D7_MIT_v3"
}

scaffold = "${OUTDIR}/ragtag.scaffold.fasta"
output   = "${OUTDIR}/ragtag.chromosomes.fasta"

kept = 0
with open(output, "w") as out:
    for rec in SeqIO.parse(scaffold, "fasta"):
        new_id = rec.id.replace("_RagTag", "")
        if new_id in ref_chrs:
            rec.id = new_id
            rec.description = ""
            SeqIO.write(rec, out, "fasta")
            kept += 1
            print(f"  Kept: {new_id}")

print(f"Total: {kept} chromosomes written to {output}")
EOF

echo ""
echo "=== Result ==="
echo "Full scaffold:  ${OUTDIR}/ragtag.scaffold.fasta"
echo "Chromosomes:    ${OUTDIR}/ragtag.chromosomes.fasta"
echo "Step 09 complete."
