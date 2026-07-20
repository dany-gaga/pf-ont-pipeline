# Lessons Learned

Validated on GM231056 (Run 3, R10.4.1, SUP basecalling) at MRCG@LSHTM, June 2026.

---

## Data

**P. falciparum cultures contain ~93% human DNA.**  
Without human depletion, Flye assembles 915 Mb of mixed human/Pf sequence (22,070 contigs, 4x coverage). With depletion: 23.9 Mb clean assembly (79 contigs, 18x coverage).

**Use negative filtering, not positive filtering.**  
Mapping to 3D7 and keeping mapped reads creates reference bias — divergent var/rifin/stevor alleles that differ from 3D7 are discarded. Mapping to hg38 and keeping unmapped reads avoids this.

**NanoFilt thresholds are run-specific.**  
Set `--length` based on the run N50. Using 1000 bp on Run 1+2 data (N50 ~763 bp) would discard most reads.

---

## Tools

**Flye:** Must `export PATH=/path/to/bin:$PATH` before running. Flye calls minimap2 internally as a subprocess — using a full path to Flye alone is not sufficient.

**Medaka API changed in v6+.** Old: `medaka consensus` + `medaka stitch`. New: `medaka inference` + `medaka sequence`. Add `--cpu` flag on CPU-only nodes.

**BUSCO:** Database renamed `apicomplexa_odb10` → `apicomplexa_odb12.2` in BUSCO v6. Check current name: `busco --list-datasets | grep apicomplexa`

**Liftoff:** `-f` flag requires a file, not a string. `echo "protein_coding_gene" > features.txt` then `liftoff -f features.txt`. Using `-f protein_coding_gene` gives `FileNotFoundError`.

**Clair3 v2:** Requires PyTorch models (`.pt` files). Download from `clair3_models_rerio_pytorch/` not `clair3_models/` (TensorFlow only). Two files: `pileup.pt` + `full_alignment.pt`.

**Clair3:** MUST use reads-to-reference BAM (`-x map-ont`). Assembly-to-reference BAM (`-x asm5`) gives 0 positions processed — Clair3 needs read pileups, not assembly alignments.

**Clair3 VCF:** Depth is `FORMAT/DP` not `INFO/DP`. BCFtools filter: `FORMAT/DP>=4` not `INFO/DP>=4`.

**SnpEff:** `$SNPEFF_JAR` is NOT set by the HPC module. Use full path to the jar. PlasmoDB-68 not in built-in databases — build custom database with `setup/build_snpeff_db.sh`.

**Syri:** Requires `--eqx` in minimap2. Incompatible with pandas >= 2.0 — pin `pandas<2.0`. Use `-c` flag (not `--bam`). Run from output directory. Needs 1-to-1 chromosome matching — use RagTag-scaffolded chromosomes, not raw contigs.

**RagTag:** Adds `_RagTag` suffix to sequence names. Must remove suffix before Syri can match chromosome names to reference.

---

## HPC-specific (MRCG cluster)

- `wget` not available on compute nodes — use `curl -L`
- GitHub and `media.githubusercontent.com` blocked — use direct server URLs
- Module system (lua) broken on some nodes — use full pixi paths as fallback
- SLURM jobs do not inherit PATH — use full paths to all tools
- `$SNPEFF_JAR` not set by the `snpEff/5.2` module
