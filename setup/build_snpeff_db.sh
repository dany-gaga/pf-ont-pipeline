#!/bin/bash
# =============================================================================
# setup/build_snpeff_db.sh
# Build custom SnpEff database from PlasmoDB-68 GFF annotation.
#
# PlasmoDB-68 is NOT included in SnpEff's built-in database list.
# This script builds a local database in resources/snpeff_db/.
# Run once before starting the pipeline.
#
# -noCheckProtein and -noCheckCds: bypass protein/CDS validation.
# These checks require protein.fa and cds.fa files that PlasmoDB
# does not provide — the database builds correctly without them.
# =============================================================================

PIPELINE_DIR=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete
REF=${PIPELINE_DIR}/resources/ref/PlasmoDB-68_Pfalciparum3D7_Genome.fasta
GFF=${PIPELINE_DIR}/resources/ref/PlasmoDB-68_Pfalciparum3D7.gff
DB_DIR=${PIPELINE_DIR}/resources/snpeff_db
SNPEFF_JAR=/mnt/software/apps/snpEff-5.2/snpEff.jar

echo "=== Building SnpEff database: Pfalciparum3D7_68 ==="

# Create database directory
mkdir -p ${DB_DIR}/Pfalciparum3D7_68

# Copy reference files
cp ${REF} ${DB_DIR}/Pfalciparum3D7_68/sequences.fa
cp ${GFF} ${DB_DIR}/Pfalciparum3D7_68/genes.gff

# Create config file
cat > ${DB_DIR}/snpEff.config << 'EOF'
data.dir = ./
Pfalciparum3D7_68.genome : Plasmodium falciparum 3D7 PlasmoDB-68
EOF

# Build database
module load java/21.0.2 2>/dev/null

cd ${DB_DIR}
java -jar ${SNPEFF_JAR} build \
    -config ${DB_DIR}/snpEff.config \
    -dataDir ${DB_DIR} \
    -gff3 \
    -noCheckProtein \
    -noCheckCds \
    -v \
    Pfalciparum3D7_68 \
2>&1 | tail -15

echo ""
echo "=== Verify database ==="
if [[ -f ${DB_DIR}/Pfalciparum3D7_68/snpEffectPredictor.bin ]]; then
    SIZE=$(ls -lh ${DB_DIR}/Pfalciparum3D7_68/snpEffectPredictor.bin | awk '{print $5}')
    echo "SUCCESS: snpEffectPredictor.bin built (${SIZE})"
    ls -lh ${DB_DIR}/Pfalciparum3D7_68/
else
    echo "ERROR: Database build failed. Check output above." >&2
    exit 1
fi
