#!/bin/bash
# =============================================================================
# 15_syri_svs.sh
# Structural variant detection using Syri.
#
# Two sub-steps:
#   15a: Align scaffolded chromosomes to 3D7 reference (asm5 + --eqx)
#   15b: Run Syri on the chromosome-scale alignment
#
# Requirements:
#   1. Use ragtag.chromosomes.fasta (from step 09), NOT the contig assembly.
#      Syri needs 1-to-1 chromosome matching. Raw contigs span multiple
#      chromosomes and cause "Unequal number of chromosomes" error.
#
#   2. minimap2 must use --eqx flag.
#      Syri needs X (mismatch) and = (match) CIGAR operations.
#      Without --eqx, minimap2 outputs M (ambiguous) and Syri fails.
#
#   3. pandas < 2.0 required.
#      Syri 1.7.1 is incompatible with pandas 2.x.
#      Pin: pandas = ">=1.3,<2.0"
#
#   4. Run Syri FROM its output directory (not with --prefix full path).
#      Full paths in --prefix cause logging configuration failure.
#
# --nosnp: skip SNP calling — better SNPs already from Clair3 (step 12).
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

CHROMOSOMES=${WORKDIR}/04_scaffold/ragtag.chromosomes.fasta
BAM=${WORKDIR}/07_variants/assembly_to_ref/assembly_to_ref.bam
OUTDIR=${WORKDIR}/07_variants/syri

echo "=== Step 15: Syri structural variant detection ==="
echo "Sample:      ${SAMPLE}"
echo "Chromosomes: ${CHROMOSOMES}"
echo "Reference:   ${REF}"

if [[ ! -f ${CHROMOSOMES} ]]; then
    echo "ERROR: Chromosome FASTA not found: ${CHROMOSOMES}" >&2
    echo "Run 09_ragtag_scaffold.sh first." >&2
    exit 1
fi

module load minimap2/2.28 samtools/1.19.2 2>/dev/null || \
    export PATH=${PIXI}:$PATH

# ── Step 15a: Assembly to reference alignment ────────────────────────────────
echo ""
echo "--- 15a: Assembly-to-reference alignment (asm5 + --eqx) ---"

mkdir -p ${WORKDIR}/07_variants/assembly_to_ref

minimap2 \
    -ax asm5 \
    --eqx \
    --secondary=no \
    -t ${THREADS} \
    ${REF} \
    ${CHROMOSOMES} \
2> ${WORKDIR}/logs/15a_assembly_to_ref.log \
| samtools sort -@ ${THREADS} \
    -o ${BAM}

samtools index ${BAM}

echo "Chromosomes aligned: $(samtools idxstats ${BAM} | grep -v '*' | awk '$3>0' | wc -l)"

# ── Step 15b: Syri ───────────────────────────────────────────────────────────
echo ""
echo "--- 15b: Syri SV detection ---"

cd ${OUTDIR}

${PIXI}/syri \
    -c ${BAM} \
    -F B \
    -r ${REF} \
    -q ${CHROMOSOMES} \
    --nc 4 \
    --nosnp \
2> ${WORKDIR}/logs/15b_syri.log

if [[ ! -f ${OUTDIR}/syri.vcf ]]; then
    echo "ERROR: Syri failed. Check logs/15b_syri.log" >&2
    cat ${WORKDIR}/logs/15b_syri.log | tail -10 >&2
    exit 1
fi

echo ""
echo "=== SV type summary ==="
grep -v "^#" ${OUTDIR}/syri.vcf \
    | cut -f5 \
    | sort | uniq -c | sort -rn \
    | grep -v "^$"

echo ""
echo "File: ${OUTDIR}/syri.vcf"
echo "Step 15 complete."
