#!/bin/bash
# =============================================================================
# 13_bcftools_filter.sh
# Apply hard quality filters to Clair3 VCF output.
#
# Filters: QUAL >= 20 AND FORMAT/DP >= 4
#
# NOTE: Use FORMAT/DP (not INFO/DP).
# Clair3 stores read depth in the FORMAT field, not INFO.
# Using INFO/DP will produce an error: "No such INFO field: DP"
#
# Typical result for a Gambian Pf isolate vs 3D7:
#   Raw:      ~170,000 variants
#   Filtered: ~37,000 variants (78% removed as low-quality)
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/07_variants/clair3/merge_output.vcf.gz
OUTPUT=${WORKDIR}/07_variants/filtered/${SAMPLE}.filtered.vcf.gz

echo "=== Step 13: BCFtools variant filtering ==="
echo "Sample:  ${SAMPLE}"
echo "Filter:  QUAL>=20 AND FORMAT/DP>=4"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input VCF not found: ${INPUT}" >&2
    exit 1
fi

module load bcftools/1.19 2>/dev/null || \
    export PATH=${PIXI}:$PATH

bcftools filter \
    --include 'QUAL>=20 && FORMAT/DP>=4' \
    --output-type z \
    --output ${OUTPUT} \
    ${INPUT}

bcftools index --tbi ${OUTPUT}

echo ""
echo "=== Variant counts ==="
echo "Before filtering:"
bcftools stats ${INPUT}  | grep "^SN" | grep -E "SNPs|indels|records"
echo ""
echo "After filtering:"
bcftools stats ${OUTPUT} | grep "^SN" | grep -E "SNPs|indels|records"

echo ""
echo "File: ${OUTPUT}"
echo "Step 13 complete."
