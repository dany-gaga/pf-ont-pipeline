#!/bin/bash
# =============================================================================
# 00_setup_variables.sh
# Source this file at the start of every session and every script.
# All per-sample values are set here — change only this file between samples.
# Usage: source scripts/00_setup_variables.sh
# =============================================================================

# ── Sample identity ───────────────────────────────────────────────────────────
export SAMPLE="GM231056"
export BARCODE="09"
export RUN="3"
export BASECALLER="SUP"           # SUP (Runs 1-3) or HAC (Run 4)

# ── Input files ───────────────────────────────────────────────────────────────
# BAM input (Runs 1-3):
export INPUT_BAM=/mnt/scratch/Martha/muhammed/Nanopore_VariantCalling_Pipeline/results/preprocess/concat/PFAL_2/barcode09.pass.bam
# FASTQ input (Run 4 — uncomment):
# export INPUT_FASTQ=/path/to/PFAL_3/barcode59.pass.fastq.gz
# Two-run merged (comma-separated):
# export INPUT_BAM=/path/run1/barcode03.bam,/path/run2/barcode03.pass.bam

# ── Output directory ──────────────────────────────────────────────────────────
export WORKDIR=/home/mrc.gm/hsaizonou/ONT_parasites/results/${SAMPLE}

# ── Reference genome (PlasmoDB-68) ───────────────────────────────────────────
export REF=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/ref/PlasmoDB-68_Pfalciparum3D7_Genome.fasta
export REF_GFF=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/ref/PlasmoDB-68_Pfalciparum3D7.gff

# ── Databases ─────────────────────────────────────────────────────────────────
export HG38_MMI=/mnt/scratch/Martha/dukpe/databases/hg38/hg38_no_alt.mmi
export KRAKEN_DB=/mnt/scratch/Martha/dukpe/databases/kraken2

# ── Tool paths ────────────────────────────────────────────────────────────────
export PIXI=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/.pixi/envs/default/bin
export SNPEFF_JAR=/mnt/software/apps/snpEff-5.2/snpEff.jar
export SNPEFF_DB_DIR=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/snpeff_db
export SNPEFF_DB=Pfalciparum3D7_68

# ── Per-run NanoFilt thresholds ───────────────────────────────────────────────
# Run 1+2 (N50 ~763bp):   Q=12  len=500
# Run 3   (N50 ~5635bp):  Q=15  len=1000
# Run 4   (N50 ~10118bp): Q=15  len=2000
export NANOFILT_Q=15
export NANOFILT_LEN=1000

# ── Per-sample model paths ────────────────────────────────────────────────────
export MEDAKA_MODEL="r1041_e82_400bps_sup_v4.3.0"
export CLAIR3_MODEL=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/clair3_models/r1041_e82_400bps_sup_v420
# HAC (Run 4) — uncomment:
# export MEDAKA_MODEL="r1041_e82_400bps_hac_v5.2.0"
# export CLAIR3_MODEL=/path/to/clair3_models/r1041_e82_400bps_hac_v520

# ── Compute resources ─────────────────────────────────────────────────────────
export THREADS=16
export MEM_GB=32

# ── Create output directories ─────────────────────────────────────────────────
mkdir -p ${WORKDIR}/00_convert
mkdir -p ${WORKDIR}/01_filter
mkdir -p ${WORKDIR}/02_qc/nanoplot
mkdir -p ${WORKDIR}/03_assembly/flye
mkdir -p ${WORKDIR}/04_polish/medaka
mkdir -p ${WORKDIR}/04_scaffold
mkdir -p ${WORKDIR}/05_qc_asm/quast
mkdir -p ${WORKDIR}/05_qc_asm/busco
mkdir -p ${WORKDIR}/06_annotation
mkdir -p ${WORKDIR}/07_variants/reads_to_ref
mkdir -p ${WORKDIR}/07_variants/assembly_to_ref
mkdir -p ${WORKDIR}/07_variants/clair3
mkdir -p ${WORKDIR}/07_variants/filtered
mkdir -p ${WORKDIR}/07_variants/snpeff
mkdir -p ${WORKDIR}/07_variants/syri
mkdir -p ${WORKDIR}/logs

echo "Variables set for sample: ${SAMPLE} (Run ${RUN}, ${BASECALLER})"
echo "Working directory: ${WORKDIR}"
