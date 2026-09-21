[![Runs successfully](https://github.com/houlstonlab/select-cohort-variants/actions/workflows/runs-successfully.yml/badge.svg)](https://github.com/houlstonlab/select-cohort-variants/actions/workflows/runs-successfully.yml)

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
    --categories Pathogenic,Damaging,Rare
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

**Allele Frequency Parameters**
- `MAF`: Default 0.5 - Maximum minor allele frequency threshold
- `AF`: Default 0.5 - Maximum allele frequency threshold
- `AF_COL`: Default 'gnomADe_AF' - Column name for population allele frequency
- `AC`: Default 1 - Minimum allele count
- `AC_COL`: Default 'AC' - Column name for allele count

**Functional Score Parameters**
- `CADD`: Default 5 - Minimum CADD score
- `DS`: Default 0.2 - Minimum delta score (SpliceAI)

**Hardy-Weinberg Equilibrium**
- `HWE`: Default 1e-5 - Hardy-Weinberg equilibrium test p-value cutoff
- `ExcHet`: Default 0.5 - Excess heterozygosity cutoff

**Annotation Settings**
- `vep_tag`: Default 'CSQ' - VEP annotation tag in VCF
- `freq_tag`: Default 'VEP' - Frequency tag prefix
- `annotate`: Default false - Use separate annotation file

#### Regional Selection
- `coding`: Default false - Restrict analysis to coding regions only
- `genome`: Default 'hg38' - Reference genome version
- `style`: Default 'UCSC' - Chromosome naming style ('UCSC' or 'NCBI')

#### Filtering Options
- `pass`: Default true - Only include variants with PASS filter
- `normalize`: Default true - Normalize VCF before processing
- `fill`: Default true - Fill missing genotypes
- `remove_lc`: Default true - Remove low complexity regions
- `remove_common`: Default true - Remove common variants
- `remove_benign`: Default true - Remove benign variants
- `remove_vus`: Default true - Remove variants of uncertain significance
- `family_id`: Default true - Use family ID information

#### General Parameters
- `chunk`: Default 100000000 - Chunk size for parallel processing
- `cohort_type`: Default 'cases' - Cohort type ('cases' or 'controls')
- `variables`: Default 'rlist,snplist,frqx,frq.strat,frq.cc,frq.counts' - Output statistics to generate
- `output_dir`: Output directory for results

### Output

The pipeline consists of multiple subworkflows executed in sequence:

1. `get_coordinates`: Retrieves gene coordinates from genelist or genomic regions
2. `get_cohort`: Extracts cohort information and pedigree data
3. `select_variants`: Filters variants based on selection criteria
4. `summarize_cases`: Generates frequency statistics for case cohorts
5. `summarize_controls`: Generates frequency statistics for control cohorts

Output directory structure:
- `coordinates/`: Gene coordinate files
- `pheno/`: VCF files split by chromosome
- `filtered/`: Filtered VCF files meeting selection criteria
- `combined/`: Combined VCF files across samples
- `variants/`: Variant frequency tables
- `aggregate/`: Aggregated variant counts by gene
- `reports/`: Summary statistics and quality control reports
