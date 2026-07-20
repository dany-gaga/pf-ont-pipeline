# Per-Run Parameter Guide

## Sequencing runs

| Run | Flow cell | Date | Basecaller | Barcodes | N50 | Status |
|-----|-----------|------|-----------|---------|-----|--------|
| Run 1 | PBI25076 | Feb 2026 | SUP v5.2 | 01-08 | ~763 bp | Stopped/Failed |
| Run 2 | PBI25223 | Mar 2026 | SUP | 01-08 | ~799 bp | Finished |
| Run 3 | PBG83776 | Mar 2026 | SUP | 09-31 | ~5,635 bp | Finished |
| Run 4 | PBK61258 | May 2026 | HAC v5.2 | 56-68 | ~10,118 bp | Finished |

---

## NanoFilt thresholds

Set based on run N50. Rule: `--length` ≈ N50 ÷ 6.

| Run | N50 | --quality | --length | Rationale |
|-----|-----|-----------|---------|-----------|
| Run 1+2 | ~763-799 bp | 12 | 500 | Short reads — use lower thresholds to retain data |
| Run 3 | ~5,635 bp | 15 | 1,000 | Long reads — can afford stricter filtering |
| Run 4 | ~10,118 bp | 15 | 2,000 | Very long reads — remove short fragments |

---

## Medaka models

Model must match the basecaller used during sequencing.

| Run | Basecaller | Medaka model |
|-----|-----------|-------------|
| Run 1 | SUP v5.2 | `r1041_e82_400bps_sup_v4.3.0` |
| Run 2 | SUP | `r1041_e82_400bps_sup_v4.3.0` |
| Run 3 | SUP | `r1041_e82_400bps_sup_v4.3.0` |
| Run 4 | HAC v5.2 | `r1041_e82_400bps_hac_v5.2.0` |

Check available models: `medaka tools list_models 2>&1 | grep r1041`

---

## Clair3 models

| Run | Basecaller | Clair3 model directory |
|-----|-----------|----------------------|
| Run 1-3 | SUP | `clair3_models/r1041_e82_400bps_sup_v420/` |
| Run 4 | HAC | `clair3_models/r1041_e82_400bps_hac_v520/` |

---

## Input file locations

| Run | Format | Location |
|-----|--------|----------|
| Run 1 (bc01-08) | BAM | `PFAL_1/barcode0X.bam` |
| Run 3 (bc09-31) | BAM | `PFAL_2/barcode0X.pass.bam` |
| Run 4 (bc56-68) | FASTQ.gz | `PFAL_3/barcode5X.pass.fastq.gz` |

> **Note:** PFAL_2 barcodes 01-08 contain <10 reads each — not usable.  
> Run 2 data for barcodes 01-08 is not accessible in this dataset.  
> Use PFAL_1 only for barcode 01-08 samples.

---

## Sample coverage summary

| Sample | Run | Barcode | Pass coverage | Notes |
|--------|-----|---------|-------------|-------|
| GM251071 | 1 | 03 | 68.6x | Run 1 only |
| Ghana_E365B_HM | 1 | 04 | 405.2x | Run 1 only |
| GM247066_HM | 1 | 05 | 95.3x | Run 1 only |
| Sen_YB010_HM | 1 | 06 | 435.3x | Run 1 only |
| Ghana_E018_HM | 1 | 07 | 252.0x | Run 1 only |
| GM231056 | 3 | 09 | 268.9x | **Validated sample** |
| GM237057 | 3 | 10 | 180.5x | |
| GM239020 | 3 | 11 | 126.5x | |
| GM241003 | 3 | 12 | 126.8x | |
| GM241005 | 3 | 13 | 117.1x | |
| GM241008 | 3 | 14 | 120.4x | |
| GM242026 | 3 | 15 | 175.2x | |
| GM242029 | 3 | 16 | 116.2x | |
| GM242043 | 3 | 17 | 180.2x | |
| GM242046 | 3 | 18 | 115.5x | |
| GM242049 | 3 | 19 | 160.9x | |
| GM247002 | 3 | 20 | 209.4x | |
| GM247003 | 3 | 21 | 91.6x | |
| GM247005 | 3 | 22 | 129.4x | |
| GM247025 | 3 | 23 | 156.8x | |
| GM247032 | 3 | 24 | 138.1x | |
| GM247036 | 3 | 25 | 115.7x | |
| GM247050 | 3 | 26 | 152.1x | |
| GM247052 | 3 | 27 | 110.4x | |
| GM247056 | 3 | 28 | 94.9x | |
| GM247066 | 3 | 29 | 129.4x | |
| GM247069 | 3 | 30 | 147.1x | |
| GM247082 | 3 | 31 | 95.6x | |
| GM247119 | 4 | 59 | 310.7x | HAC |
| GM247120 | 4 | 60 | 141.4x | HAC |
| GM247127 | 4 | 61 | 350.4x | HAC |
| GM251011 | 4 | 62 | 532.9x | HAC |
| GM251046 | 4 | 63 | 352.7x | HAC |
| GM251048 | 4 | 64 | 323.6x | HAC |
| TES13 | 4 | 65 | 461.4x | HAC, Madagascar/Gambia |
| TES17_1 | 4 | 66 | 292.4x | HAC, Madagascar/Gambia |
| TES17_2 | 4 | 67 | 266.8x | HAC, Madagascar/Gambia |
| TES18 | 4 | 68 | 133.0x | HAC, Madagascar/Gambia |
