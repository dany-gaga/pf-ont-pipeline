#!/bin/bash
# =============================================================================
# setup/download_databases.sh
# Download and index hg38 and Kraken2 databases.
# Run once before starting the pipeline.
# Requires ~20 GB disk space.
# =============================================================================

DB_DIR=/mnt/scratch/Martha/dukpe/databases
PIXI=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/.pixi/envs/default/bin

mkdir -p ${DB_DIR}/hg38
mkdir -p ${DB_DIR}/kraken2

echo "=== Downloading hg38 reference (~3 GB) ==="
curl -L \
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz \
    -o ${DB_DIR}/hg38/hg38_no_alt.fna.gz \
    --progress-bar

echo "Decompressing hg38..."
gunzip -k ${DB_DIR}/hg38/hg38_no_alt.fna.gz

echo "Building minimap2 index for hg38 (saves ~4 min per sample)..."
${PIXI}/minimap2 \
    -d ${DB_DIR}/hg38/hg38_no_alt.mmi \
    -x map-ont \
    ${DB_DIR}/hg38/hg38_no_alt.fna
echo "hg38 done: $(ls -lh ${DB_DIR}/hg38/hg38_no_alt.mmi)"

echo ""
echo "=== Downloading Kraken2 PlusPF 16GB database ==="
echo "(Bacteria + Archaea + Human + Viral + Protozoa + Fungi)"
curl -L \
    https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16gb_20231009.tar.gz \
    -o ${DB_DIR}/kraken2/k2_pluspf_16gb.tar.gz \
    --progress-bar

echo "Extracting Kraken2 database..."
tar -xzf ${DB_DIR}/kraken2/k2_pluspf_16gb.tar.gz \
    -C ${DB_DIR}/kraken2/

echo ""
echo "=== All done ==="
echo "hg38:"
ls -lh ${DB_DIR}/hg38/
echo ""
echo "Kraken2:"
ls -lh ${DB_DIR}/kraken2/*.k2d 2>/dev/null | head -5
