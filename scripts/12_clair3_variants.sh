#!/bin/bash
# =============================================================================
# 12_clair3_variants.sh
# SNP and indel calling using Clair3.
#
# --haploid_sensitive: CRITICAL for P. falciparum.
#   Pf in culture is clonal (haploid). Diploid mode creates spurious
#   heterozygous calls at ~50% AF that don't exist in the genome.
#
# --no_phasing_for_fa: required for haploid organisms.
#
# Clair3 model: must match basecaller chemistry exactly.
#   PyTorch models (.pt) required for Clair3 v2.
#   Download from: bio8.cs.hku.hk/clair3/clair3_models_rerio_pytorch/
#   NOT from the main clair3_models/ directory (TensorFlow only).
#
# Depth field: FORMAT/DP (not INFO/DP) in Clair3 VCF output.
# =============================================================================

source "$(dirname "$0")/00_setup_variables.sh"

BAM=${WORKDIR}/07_variants/reads_to_ref/reads_to_ref.bam
OUTDIR=${WORKDIR}/07_variants/clair3

echo "=== Step 12: Clair3 variant calling ==="
echo "Sample:  ${SAMPLE}"
echo "BAM:     ${BAM}"
echo "Model:   ${CLAIR3_MODEL}"

if [[ ! -f ${BAM} ]]; then
    echo "ERROR: BAM not found: ${BAM}" >&2
    echo "Run 11_reads_to_ref.sh first." >&2
    exit 1
fi
if [[ ! -f ${CLAIR3_MODEL}/pileup.pt ]]; then
    echo "ERROR: Clair3 model not found: ${CLAIR3_MODEL}/pileup.pt" >&2
    echo "Run setup/download_clair3_models.sh first." >&2
    exit 1
fi

export PATH=${PIXI}:$PATH

${PIXI}/run_clair3.sh \
    --bam_fn=${BAM} \
    --ref_fn=${REF} \
    --threads=${THREADS} \
    --platform="ont" \
    --model_path=${CLAIR3_MODEL} \
    --output=${OUTDIR} \
    --haploid_sensitive \
    --no_phasing_for_fa \
    --include_all_ctgs \
    --gvcf \
    --min_coverage=4 \
    --remove_intermediate_dir \
2> ${WORKDIR}/logs/12_clair3.log

echo ""
echo "=== Raw variant counts ==="
${PIXI}/bcftools stats ${OUTDIR}/merge_output.vcf.gz \
    | grep "^SN"

echo ""
echo "Files:"
ls -lh ${OUTDIR}/merge_output.vcf.gz ${OUTDIR}/merge_output.gvcf.gz
echo "Step 12 complete."
