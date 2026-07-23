#!/bin/bash
# =============================================================================
# 04_kraken_filter.sh
# Taxonomic classification and bacterial/fungal exclusion using Kraken2.
#
# Strategy: EXCLUDE confirmed bacteria (taxid 2) and fungi (taxid 4751).
# Keep everything else: Plasmodium reads + unclassified reads.
# Unclassified reads include divergent Pf alleles not in the Kraken database
# — these are important for complete subtelomeric assembly.
#
# Database: PlusPF 16GB (Bacteria + Archaea + Human + Protozoa + Fungi + Viral)
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/01_filter/${SAMPLE}_non_human.fastq.gz
REPORT=${WORKDIR}/02_qc/${SAMPLE}_kraken_report.txt
KRAKEN_OUT=${WORKDIR}/02_qc/${SAMPLE}_kraken_output.txt
OUTPUT=${WORKDIR}/01_filter/${SAMPLE}_pf_clean.fastq.gz

mkdir -p ${WORKDIR}/02_qc

echo "=== Step 04: Kraken2 taxonomic filtering ==="
echo "Sample:     ${SAMPLE}"
echo "Input:      ${INPUT}"
echo "Kraken DB:  ${KRAKEN_DB}"
echo "Excluding:  Bacteria (taxid 2), Fungi (taxid 4751)"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input not found: ${INPUT}" >&2
    exit 1
fi
if [[ ! -f ${KRAKEN_DB}/hash.k2d ]]; then
    echo "ERROR: Kraken2 database not found: ${KRAKEN_DB}" >&2
    exit 1
fi

module load kraken2/2.17.1 2>/dev/null

BEFORE=$(zcat ${INPUT} | awk 'NR%4==1' | wc -l)

# Step 1: classify reads
kraken2 \
    --db ${KRAKEN_DB} \
    --threads ${THREADS} \
    --gzip-compressed \
    --report ${REPORT} \
    --output ${KRAKEN_OUT} \
    ${INPUT} \
2> ${WORKDIR}/logs/04_kraken.log

# Step 2: exclude bacteria and fungi, keep rest
${PIXI}/extract_kraken_reads.py \
    -k ${KRAKEN_OUT} \
    -s ${INPUT} \
    -o /dev/stdout \
    -r {output.report} \
    -t 2 4751 \
    --exclude \
    --include-children \
2>> ${WORKDIR}/logs/04_kraken.log \
| ${PIXI}/pigz -p ${THREADS} \
    > ${OUTPUT}

# Clean up large kraken output
rm -f ${KRAKEN_OUT}

AFTER=$(zcat ${OUTPUT} | awk 'NR%4==1' | wc -l)
REMOVED=$((BEFORE - AFTER))

echo ""
echo "=== Result ==="
echo "Before:   ${BEFORE} reads"
echo "After:    ${AFTER} reads"
echo "Removed:  ${REMOVED} bacterial/fungal reads"
echo "Report:   ${REPORT}"
echo "File:     ${OUTPUT}"
echo "Step 04 complete."
