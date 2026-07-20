#!/bin/bash
# =============================================================================
# 14_snpeff_annotation.sh
# Functional annotation of variants using SnpEff.
#
# Uses a custom PlasmoDB-68 database (not in SnpEff built-ins).
# Build the database once with: setup/build_snpeff_db.sh
#
# $SNPEFF_JAR is NOT set by the HPC module — use full path.
# The HPC module sets $SNPEFF_DIR but not $SNPEFF_JAR.
#
# Impact levels:
#   HIGH:     stop gain, frameshift — likely disruptive
#   MODERATE: missense — amino acid change
#   LOW:      synonymous — silent
#   MODIFIER: intergenic, intronic
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

INPUT=${WORKDIR}/07_variants/filtered/${SAMPLE}.filtered.vcf.gz
OUTPUT=${WORKDIR}/07_variants/snpeff/${SAMPLE}.ann.vcf.gz
HTML=${WORKDIR}/07_variants/snpeff/${SAMPLE}.snpeff_summary.html
CSV=${WORKDIR}/07_variants/snpeff/${SAMPLE}.snpeff_summary.csv

echo "=== Step 14: SnpEff functional annotation ==="
echo "Sample:   ${SAMPLE}"
echo "Database: ${SNPEFF_DB}"

if [[ ! -f ${INPUT} ]]; then
    echo "ERROR: Input VCF not found: ${INPUT}" >&2
    exit 1
fi
if [[ ! -f ${SNPEFF_DB_DIR}/Pfalciparum3D7_68/snpEffectPredictor.bin ]]; then
    echo "ERROR: SnpEff database not built." >&2
    echo "Run setup/build_snpeff_db.sh first." >&2
    exit 1
fi

module load java/21.0.2 2>/dev/null

java -Xmx6g -jar ${SNPEFF_JAR} \
    -config ${SNPEFF_DB_DIR}/snpEff.config \
    -dataDir ${SNPEFF_DB_DIR} \
    ${SNPEFF_DB} \
    -v \
    -stats ${HTML} \
    -csvStats ${CSV} \
    ${INPUT} \
2> ${WORKDIR}/logs/14_snpeff.log \
| ${PIXI}/bgzip -c \
    > ${OUTPUT}

${PIXI}/bcftools index --tbi ${OUTPUT}

echo ""
echo "=== Effect summary ==="
grep "^Type" -A 6 ${CSV} | head -20
echo ""
echo "=== Impact summary ==="
grep "^Type" -A 6 ${CSV} | grep -A 6 "by impact" | head -10

echo ""
echo "Files:"
echo "  Annotated VCF: ${OUTPUT}"
echo "  HTML report:   ${HTML}"
echo "Step 14 complete."
