#!/bin/bash
# =============================================================================
# 01_convert_to_fastq.sh
# Convert input BAM(s) or FASTQ(s) to a single merged FASTQ.gz.
# Handles: single BAM, single FASTQ.gz, or multiple files (comma-separated).
# Skip this step if input is already a single FASTQ.gz.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

echo "=== Step 01: BAM to FASTQ conversion ==="
echo "Sample:  ${SAMPLE}"
echo "Input:   ${INPUT_BAM:-${INPUT_FASTQ}}"
echo "Output:  ${WORKDIR}/00_convert/${SAMPLE}_raw.fastq.gz"

# Check samtools available
module load samtools/1.19.2 2>/dev/null || \
    export PATH=${PIXI}:$PATH

# Convert and merge all input files
OUTPUT=${WORKDIR}/00_convert/${SAMPLE}_raw.fastq.gz

(
IFS=',' read -ra FILES <<< "${INPUT_BAM:-${INPUT_FASTQ}}"
for f in "${FILES[@]}"; do
    f=$(echo "$f" | tr -d ' ')
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Input file not found: $f" >&2
        exit 1
    fi
    if [[ "$f" == *.bam ]]; then
        echo "  Converting BAM: $f" >&2
        samtools fastq -@ ${THREADS} "$f"
    elif [[ "$f" == *.gz ]]; then
        echo "  Decompressing FASTQ: $f" >&2
        zcat "$f"
    else
        echo "  Reading FASTQ: $f" >&2
        cat "$f"
    fi
done
) 2> ${WORKDIR}/logs/01_convert.log \
| ${PIXI}/pigz -p ${THREADS} \
    > ${OUTPUT}

# Verify
READS=$(zcat ${OUTPUT} | awk 'NR%4==1' | wc -l)
SIZE=$(ls -lh ${OUTPUT} | awk '{print $5}')

echo ""
echo "=== Result ==="
echo "Reads:  ${READS}"
echo "Size:   ${SIZE}"
echo "File:   ${OUTPUT}"

if [[ ${READS} -eq 0 ]]; then
    echo "ERROR: Output file is empty. Check logs/01_convert.log" >&2
    exit 1
fi

echo "Step 01 complete."
