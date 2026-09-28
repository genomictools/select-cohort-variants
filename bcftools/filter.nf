process FILTER {
    tag "${cohort}:${key}:${category}"

    label 'simple'
	label 'bcftools'

    publishDir("${params.output_dir}/filtered/", mode: 'copy')

    input:
    tuple val(cohort), val(key),
          path(file), path(index),
          val(n_samples), val(n_variants),
          val(category)

    output:
    tuple val(cohort), val(key), val(category),
          path("${cohort}.${key}.${category}.vcf.gz"),
          path("${cohort}.${key}.${category}.vcf.gz.tbi"),
          path("${cohort}.${key}.${category}.variants.txt"),
          path("${cohort}.${key}.${category}.annotations.tsv"),
          path("${cohort}.${key}.${category}.qc.tsv"),
          env(n_samples), env(n_variants)
        
    script:
    // Reliability filters
    def clv_remove = (params.remove_benign || params.remove_vus) ? true : false
    def any_remove = (params.remove_benign || params.remove_vus || params.remove_lc) ? true : false
    def rel_cols = []
    def rel_expr = []

    if (clv_remove)             { rel_cols << "CLIN_SIG" }
    if (params.remove_lc)       { rel_cols << "LoF" }
    if (params.remove_benign)   { rel_expr << "CLIN_SIG ~ 'benign'" }
    if (params.remove_vus)      { rel_expr << "CLIN_SIG ~ 'conflicting'" }
    if (params.remove_lc)       { rel_expr << "LoF = 'LC'" }

    def rel_cols_str = rel_cols.join(',')
    def rel_expr_str = rel_expr.join(' || ')

    // Category filters
    def cat_cols = []
    def cat_expr = []

    if (category == "Rare") {
        // No additional filters for Rare category
    } else if (category == "Pathogenic") {
        cat_cols << "CLIN_SIG"
        cat_expr << "CLIN_SIG ~ 'pathogenic' || CLIN_SIG ~ 'likely_pathogenic'"
    } else if (category == "High") {
        cat_cols << "IMPACT,CADD_PHRED:Float"
        cat_expr << "IMPACT='HIGH' && CADD_PHRED > ${params.CADD}"
    } else if (category == "Damaging") {
        cat_cols << "IMPACT,CADD_PHRED:Float"
        cat_expr << "(IMPACT='HIGH' || IMPACT='MODERATE') && CADD_PHRED > ${params.CADD}"
    } else if (category == "PTV") {
        cat_cols << "Consequence"
        cat_expr << "Consequence~'stop_gained' || Consequence~'frameshift_variant' || Consequence~'splice_acceptor_variant'"
    } else if (category == "Stop") {
        cat_cols << "Consequence"
        cat_expr << "Consequence~'stop_gained'"
    } else if (category == "Splicing") {
        cat_cols << "SpliceAI_pred_DS_AG:Float,SpliceAI_pred_DS_AL:Float,SpliceAI_pred_DS_DG:Float,SpliceAI_pred_DS_DL:Float"
        cat_expr << "SpliceAI_pred_DS_AG > ${params.DS} || SpliceAI_pred_DS_AL > ${params.DS} || SpliceAI_pred_DS_DG > ${params.DS} || SpliceAI_pred_DS_DL > ${params.DS}"
    } else {
        exit "Category: ${category} is not recognized"
    }
    def cat_cols_str = cat_cols.join(',')
    def cat_expr_str = cat_expr.join(' || ')

    """
    #!/bin/bash
    # Apply the filters using bcftools
    bcftools view ${file} | \
    if   [ ${params.AC} > 0 ];              then bcftools view -i "${params.AC_COL} >= ${params.AC}"; fi | \
    if   [ "${params.freq_tag}" = "VEP"  ]; then bcftools +split-vep -a "${params.vep_tag}" -s worst -c "${params.AF_COL}:Float" -e "${params.AF_COL} > ${params.AF}"; else bcftools filter -e "${params.AF_COL} > ${params.AF}" ; fi | \
    if   [ "$any_remove" = "true" ];        then bcftools +split-vep -a "${params.vep_tag}" -s worst -c "$rel_cols_str" -e "$rel_expr_str"; else bcftools view; fi | \
    if   [ "${category}" != "Rare" ];       then bcftools +split-vep -a "${params.vep_tag}" -s worst -c "$cat_cols_str" -i "$cat_expr_str"; else bcftools view; fi | \
    bcftools annotate --set-id '%CHROM:%POS:%REF:%ALT' | \
    bcftools view --threads ${task.cpus} -Oz -o ${cohort}.${key}.${category}.vcf.gz

    # Index the VCF
    tabix ${cohort}.${key}.${category}.vcf.gz

    # Export variant list
	bcftools query \
		-f '%CHROM:%POS:%REF:%ALT\n' \
		${cohort}.${key}.${category}.vcf.gz \
		> ${cohort}.${key}.${category}.variants.txt

    # Extract annotations
    echo -e "variant\tgene\t\$(bcftools +split-vep -l ${cohort}.${key}.${category}.vcf.gz | cut -f 2 | tr '\n' '\t' | sed 's/\t\$//')" > ${cohort}.${key}.${category}.annotations.tsv
	bcftools +split-vep \
		-s worst \
		-c Gene \
		-f '%CHROM:%POS:%REF:%ALT\t%Gene\t%CSQ\n' \
		-d -A tab \
		${cohort}.${key}.${category}.vcf.gz \
		>> ${cohort}.${key}.${category}.annotations.tsv

    # Extract allele depth
    bcftools query -f '[%CHROM:%POS:%REF:%ALT\t%SAMPLE\t%GT\t%AD\n]' \
    ${cohort}.${key}.${category}.vcf.gz \
	> ${cohort}.${key}.${category}.qc.tsv
    
    # Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.${key}.${category}.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.${key}.${category}.vcf.gz)
    """
}
