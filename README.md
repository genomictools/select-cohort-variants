### Introduction

This workflow filters and selects variants meeting specific criteria from annotated VCF files. It extracts qualifying variants based on functional annotation, population frequency, and quality metrics, then tabulates variant frequencies by gene. The workflow supports both case and control cohorts with separate summarization strategies.

The workflow is designed to:
- Filter variants by multiple quality and annotation criteria
- Select variants from defined genomic regions or gene lists
- Generate frequency tables stratified by cohort type
- Support parallel processing of large VCF files
- Provide comprehensive variant statistics and reports

### Usage

`--cohorts` is a required input CSV file containing cohort metadata and file locations.

The typical command looks like the following:

```bash
nextflow run select-cohort-variants/main.nf \
    --output_dir results/ \
    --cohorts input/cohorts_input.csv \
    --categories Pathogenic,Damaging,Splicing,High,PTV,Stop,Rare
```

### Inputs & Parameters

#### Input Files
- `cohorts`: CSV file with columns: cohort, file (VCF), index (TBI), pedigree, chrom (optional), start (optional), end (optional), genelist (optional), annot_file (optional), annot_index (optional)

#### Variant Selection Parameters

**Filtering Categories**
- `categories`: Default 'Pathogenic,Damaging,Splicing,High,PTV,Stop,Rare,Unfiltered' - Comma-separated list of variant consequence categories to include
  - `Pathogenic`: ClinVar pathogenic variants
  - `Damaging`: Predicted damaging variants (SIFT/PolyPhen)
  - `Splicing`: Splice site affecting variants
  - `High`: High-impact variants
  - `PTV`: Protein-truncating variants (frameshift, stop gained, splice donor/acceptor)
  - `Stop`: Stop gained/lost variants
  - `Rare`: Rare variants (below MAF threshold)
  - `Unfiltered`: All variants regardless of consequence

**Genotype Quality Parameters**
- `GQ`: Default 10 - Minimum genotyping quality
- `DP`: Default 5 - Minimum read depth
- `VAF`: Default 0.2 - Minimum variant allele frequency
- `missing_as_ref`: Default true - Treat missing genotypes as reference

### Output

- `results/`: Filtered and selected variants with variant counts by gene and category
- `summary/`: Comprehensive variant statistics and frequency tables
