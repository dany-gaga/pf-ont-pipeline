#!/bin/bash
# =============================================================================
# setup/download_clair3_models.sh
# Download Clair3 v2 PyTorch models.
#
# IMPORTANT: Clair3 v2 uses PyTorch (.pt files), NOT TensorFlow.
# Models must come from clair3_models_rerio_pytorch/ directory.
# The main clair3_models/ directory has TensorFlow models (incompatible).
#
# Two models needed:
#   SUP model: for Runs 1, 2, 3 (super-accuracy basecalling)
#   HAC model: for Run 4 (high-accuracy basecalling, v5.2.0)
# =============================================================================

MODEL_DIR=/home/mrc.gm/hsaizonou/ONT_parasites/pf_pipeline_complete/resources/clair3_models
BASE=https://www.bio8.cs.hku.hk/clair3/clair3_models_rerio_pytorch

echo "=== Downloading Clair3 PyTorch models ==="

# ── SUP model (Runs 1-3) ─────────────────────────────────────────────────────
echo ""
echo "--- SUP model: r1041_e82_400bps_sup_v420 ---"
mkdir -p ${MODEL_DIR}/r1041_e82_400bps_sup_v420

curl -L ${BASE}/r1041_e82_400bps_sup_v420/pileup.pt \
    -o ${MODEL_DIR}/r1041_e82_400bps_sup_v420/pileup.pt
curl -L ${BASE}/r1041_e82_400bps_sup_v420/full_alignment.pt \
    -o ${MODEL_DIR}/r1041_e82_400bps_sup_v420/full_alignment.pt

ls -lh ${MODEL_DIR}/r1041_e82_400bps_sup_v420/

# ── HAC model (Run 4) ─────────────────────────────────────────────────────────
echo ""
echo "--- HAC model: r1041_e82_400bps_hac_v420 ---"
mkdir -p ${MODEL_DIR}/r1041_e82_400bps_hac_v520

curl -L ${BASE}/r1041_e82_400bps_hac_v420/pileup.pt \
    -o ${MODEL_DIR}/r1041_e82_400bps_hac_v520/pileup.pt
curl -L ${BASE}/r1041_e82_400bps_hac_v420/full_alignment.pt \
    -o ${MODEL_DIR}/r1041_e82_400bps_hac_v520/full_alignment.pt

ls -lh ${MODEL_DIR}/r1041_e82_400bps_hac_v520/

echo ""
echo "=== Verify model files ==="
for MODEL in r1041_e82_400bps_sup_v420 r1041_e82_400bps_hac_v520; do
    PILEUP=${MODEL_DIR}/${MODEL}/pileup.pt
    FA=${MODEL_DIR}/${MODEL}/full_alignment.pt
    SIZE=$(ls -lh ${PILEUP} 2>/dev/null | awk '{print $5}')
    if [[ -f ${PILEUP} && $(stat -c%s ${PILEUP}) -gt 1000000 ]]; then
        echo "  ${MODEL}: OK (pileup.pt = ${SIZE})"
    else
        echo "  ${MODEL}: FAILED or too small — check download"
    fi
done
