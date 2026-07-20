# pf-ont-pipeline

**De novo assembly, variant calling, and pangenome construction from Oxford Nanopore sequencing of cultured *Plasmodium falciparum* isolates.**

Validated on R10.4.1 flow cells (SUP and HAC basecalling) using Gambian and West African isolates.

---

## Overview

```
Raw BAM/FASTQ
    │
    ├── 01  BAM → FASTQ conversion
    ├── 02  NanoFilt (per-run quality + length filter)
    ├── 03  Human read depletion (hg38 negative filter)
    ├── 04  Kraken2 taxonomic cleaning (remove bacteria/fungi)
    ├── 05  NanoPlot QC
    │
    ├── 06  Flye de novo assembly
    ├── 07  Medaka polishing
    ├── 08  QUAST + BUSCO quality assessment
    ├── 09  RagTag scaffolding → chromosome-scale assembly
    │
    ├── 10  Liftoff annotation projection (PlasmoDB-68)
    │
    ├── 11  Reads → reference alignment (for Clair3)
    ├── 12  Clair3 SNP + indel calling (haploid mode)
    ├── 13  BCFtools filtering (QUAL≥20, FORMAT/DP≥4)
    ├── 14  SnpEff functional annotation (custom PlasmoDB-68 db)
    ├── 15  Syri structural variant detection
    │
    └── 16  Minigraph-Cactus pangenome + Odgi analysis
```

---

## Repository structure

```
pf-ont-pipeline/
├── README.md                       ← this file
├── scripts/
│   ├── 00_setup_variables.sh       ← set all paths and parameters here
│   ├── 01_convert_to_fastq.sh
│   ├── 02_nanofilt.sh
│   ├── 03_remove_human.sh
│   ├── 04_kraken_filter.sh
│   ├── 05_nanoplot_qc.sh
│   ├── 06_flye_assembly.sh
│   ├── 07_medaka_polish.sh
│   ├── 08_quast_busco.sh
│   ├── 09_ragtag_scaffold.sh
│   ├── 10_liftoff_annotation.sh
│   ├── 11_reads_to_ref.sh
│   ├── 12_clair3_variants.sh
│   ├── 13_bcftools_filter.sh
│   ├── 14_snpeff_annotation.sh
│   ├── 15_syri_svs.sh
│   └── 16_pangenome.sh
├── setup/
│   ├── download_databases.sh       ← hg38 + Kraken2 (run once)
│   ├── download_clair3_models.sh   ← SUP + HAC models (run once)
│   └── build_snpeff_db.sh          ← PlasmoDB-68 SnpEff db (run once)
└── docs/
    ├── lessons_learned.md          ← issues discovered during validation
    └── per_run_parameters.md       ← NanoFilt/Medaka/Clair3 params by run
```

---

## Quick start

### 1. One-time setup

```bash
# Download databases (~20 GB total)
bash setup/download_databases.sh

# Download Clair3 models
bash setup/download_clair3_models.sh

# Build SnpEff database
bash setup/build_snpeff_db.sh
```

### 2. Per-sample run

Edit `scripts/00_setup_variables.sh` to set sample-specific values:
- `SAMPLE`, `INPUT_BAM`, `WORKDIR`
- `NANOFILT_Q`, `NANOFILT_LEN` (see `docs/per_run_parameters.md`)
- `MEDAKA_MODEL`, `CLAIR3_MODEL` (SUP or HAC)

Then run each step in order:

```bash
source scripts/00_setup_variables.sh

bash scripts/01_convert_to_fastq.sh
bash scripts/02_nanofilt.sh
bash scripts/03_remove_human.sh
bash scripts/04_kraken_filter.sh
bash scripts/05_nanoplot_qc.sh
bash scripts/06_flye_assembly.sh
bash scripts/07_medaka_polish.sh
bash scripts/08_quast_busco.sh
bash scripts/09_ragtag_scaffold.sh
bash scripts/10_liftoff_annotation.sh
bash scripts/11_reads_to_ref.sh
bash scripts/12_clair3_variants.sh
bash scripts/13_bcftools_filter.sh
bash scripts/14_snpeff_annotation.sh
bash scripts/15_syri_svs.sh
```

---

## Key design decisions

**Human depletion uses negative filtering** (map to hg38, keep unmapped) rather than  
positive filtering (map to 3D7, keep mapped). This avoids reference bias — divergent  
var/rifin/stevor alleles that differ from 3D7 are preserved for assembly.

**Two separate minimap2 alignments** are needed at different stages:
- `map-ont` preset (step 11): reads → reference, for Clair3 pileup-based SNP calling
- `asm5` preset (step 15): scaffolded assembly → reference, for Syri structural variants

**Clair3 runs in haploid mode** (`--haploid_sensitive`). *P. falciparum* in culture is  
clonal (haploid). Diploid mode creates spurious heterozygous calls that do not exist.

**RagTag scaffolding** (step 09) is required before Syri (step 15). Raw assembly contigs  
span multiple chromosomes and cause a "Unequal number of chromosomes" error in Syri.

---

## Expected results (validated on GM231056)

| Step | Output | Value |
|------|--------|-------|
| After NanoFilt | Reads retained | ~72% |
| After human depletion | Pf reads | ~6.6% of total |
| After Kraken filter | Clean reads | ~64,000 reads |
| Flye assembly | Contigs | 79 |
| Flye assembly | N50 | 1.44 Mb |
| Flye assembly | Total length | 23.9 Mb |
| BUSCO | Completeness | 100% |
| Liftoff | Genes mapped | 98.8% (5,252/5,318) |
| Clair3 (filtered) | SNPs vs 3D7 | ~23,400 |
| Clair3 (filtered) | Indels vs 3D7 | ~14,200 |
| Syri | Total SVs | ~322 |

---

## Reference

- **Reference genome:** *Plasmodium falciparum* 3D7, PlasmoDB release 68
- **Developed by:** Helga D.M. Saizonou, MRCG@LSHTM, 2026
- **See also:** `docs/lessons_learned.md` for troubleshooting guide
