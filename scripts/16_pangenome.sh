#!/bin/bash
# =============================================================================
# 16_pangenome.sh
# Pangenome graph construction using Minigraph-Cactus + Odgi.
#
# Run AFTER all samples have completed steps 01-09.
# Input: scaffolded assemblies from all samples (ragtag.scaffold.fasta).
#
# Requires: Singularity, GPU node (for memory — 180+ GB recommended).
# Runtime: 48-72 hours for 38 samples.
#
# Edit SAMPLES and RESULTS_DIR before running.
# =============================================================================

# ── Configuration — edit before running ──────────────────────────────────────
RESULTS_DIR=/home/mrc.gm/hsaizonou/ONT_parasites/results
PANGENOME_DIR=/home/mrc.gm/hsaizonou/ONT_parasites/pangenome
CACTUS_SIF=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/singularity/cactus_v2.8.0.sif
REF=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/ref/PlasmoDB-68_Pfalciparum3D7_Genome.fasta
PIXI=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/.pixi/envs/default/bin
THREADS=40

SAMPLES=(
    GM231056 GM237057 GM239020 GM241003 GM241005
    GM241008 GM242026 GM242029 GM242043 GM242046
    # add all samples here
)
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p ${PANGENOME_DIR}/{minigraph_cactus,odgi}

echo "=== Step 16: Pangenome construction ==="
echo "Samples: ${#SAMPLES[@]}"

module load singularity/4.1.3 2>/dev/null

# ── Step 16a: Build seqfile ───────────────────────────────────────────────────
SEQFILE=${PANGENOME_DIR}/seqfile.txt
echo "Pf3D7	${REF}" > ${SEQFILE}

for SAMPLE in "${SAMPLES[@]}"; do
    ASM=${RESULTS_DIR}/${SAMPLE}/04_scaffold/ragtag.scaffold.fasta
    if [[ -f ${ASM} ]]; then
        echo "${SAMPLE}	${ASM}" >> ${SEQFILE}
    else
        echo "WARNING: Assembly not found for ${SAMPLE}: ${ASM}" >&2
    fi
done

echo "Seqfile entries: $(wc -l < ${SEQFILE})"

# ── Step 16b: Minigraph-Cactus pangenome ─────────────────────────────────────
echo ""
echo "--- Building pangenome (this may take 48-72 hours) ---"

singularity exec \
    --bind ${PANGENOME_DIR}:/pangenome \
    --bind $(dirname ${REF}):/ref \
    ${CACTUS_SIF} \
    cactus-pangenome \
        --maxCores ${THREADS} \
        --maxMemory 180000M \
        ${PANGENOME_DIR}/minigraph_cactus/jobstore \
        ${SEQFILE} \
        --outDir ${PANGENOME_DIR}/minigraph_cactus \
        --outName pf_pangenome \
        --reference Pf3D7 \
        --gfa \
        --vcf

# ── Step 16c: Odgi graph analysis ────────────────────────────────────────────
echo ""
echo "--- Odgi graph analysis ---"

${PIXI}/odgi build \
    --graph ${PANGENOME_DIR}/minigraph_cactus/pf_pangenome.gfa \
    --out   ${PANGENOME_DIR}/odgi/pf_pangenome.og \
    --threads ${THREADS} \
    --progress

${PIXI}/odgi stats \
    --input ${PANGENOME_DIR}/odgi/pf_pangenome.og \
    --summary \
    > ${PANGENOME_DIR}/odgi/graph_stats.txt

${PIXI}/odgi paths \
    --input ${PANGENOME_DIR}/odgi/pf_pangenome.og \
    --coverage-levels 1,1 \
    --threads ${THREADS} \
    > ${PANGENOME_DIR}/odgi/path_coverage_matrix.tsv

echo ""
echo "=== Graph statistics ==="
cat ${PANGENOME_DIR}/odgi/graph_stats.txt

echo ""
echo "Files:"
echo "  GFA:            ${PANGENOME_DIR}/minigraph_cactus/pf_pangenome.gfa"
echo "  Odgi graph:     ${PANGENOME_DIR}/odgi/pf_pangenome.og"
echo "  Graph stats:    ${PANGENOME_DIR}/odgi/graph_stats.txt"
echo "  Coverage matrix:${PANGENOME_DIR}/odgi/path_coverage_matrix.tsv"
echo "Step 16 complete."
