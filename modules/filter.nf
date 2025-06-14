process FILTER {
    tag "${cohort}:${key}:${category}"

    label 'simple'

    container params.bcftools

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
          path("${cohort}.${key}.${category}.annotations.tsv"),
          env(n_samples), env(n_variants)
        
    script:
    """
    #!/bin/bash
    # Filter variants
    bcftools view -e "MAF > ${params.MAF} || HWE < ${params.HWE} || ExcHet < ${params.ExcHet}" ${file} | \
    bcftools +split-vep -s worst -c CLIN_SIG -e "CLIN_SIG ~ 'conflicting' || CLIN_SIG ~ 'benign'" | \
    if   [ ${category} == 'Pathogenic' ]; then bcftools +split-vep -s worst -c CLIN_SIG -i "CLIN_SIG ~ 'pathogenic' || CLIN_SIG ~ 'likely_pathogenic'";
    elif [ ${category} == 'Rare' ];       then bcftools +split-vep -s worst -c ${params.AF_COL}:Float,MAX_AF:Float -e "${params.AF_COL} > ${params.AF} || MAX_AF > ${params.AF}";
    elif [ ${category} == 'High' ];       then bcftools +split-vep -s worst -c IMPACT,CADD_PHRED:Float -i "IMPACT='HIGH' && CADD_PHRED > ${params.CADD}";
    elif [ ${category} == 'Damaging' ];   then bcftools +split-vep -s worst -c IMPACT,CADD_PHRED:Float -i "(IMPACT='HIGH' || IMPACT='MODERATE') && CADD_PHRED > ${params.CADD}";
    elif [ ${category} == 'PTV' ];        then bcftools +split-vep -s worst -c Consequence -i "Consequence~'stop_gained' || Consequence~'frameshift_variant' || Consequence~'splice_acceptor_variant'";
    elif [ ${category} == 'Stop' ];       then bcftools +split-vep -s worst -c Consequence -i "Consequence~'stop_gained'";
    elif [ ${category} == 'Splicing' ];   then bcftools +split-vep -s worst -c SpliceAI_pred_DS_AG:Float,SpliceAI_pred_DS_AL:Float,SpliceAI_pred_DS_DG:Float,SpliceAI_pred_DS_DL:Float -i "SpliceAI_pred_DS_AG > ${params.DS} || SpliceAI_pred_DS_AL > ${params.DS} || SpliceAI_pred_DS_DG > ${params.DS} || SpliceAI_pred_DS_DL > ${params.DS}";
    else exit "Category: ${category} is not recognized"; fi | \
    bcftools annotate --set-id '%CHROM:%POS:%REF:%ALT' | \
    bcftools view --threads ${task.cpus} -Oz -o ${cohort}.${key}.${category}.vcf.gz

    # Index the VCF
    tabix ${cohort}.${key}.${category}.vcf.gz

    # Extract annotations
	bcftools +split-vep \
		-s worst \
		-c Gene \
		-f '%CHROM:%POS:%REF:%ALT\t%Gene\t%CSQ\n' \
		-d -A tab \
		${cohort}.${key}.${category}.vcf.gz \
		> ${cohort}.${key}.${category}.annotations.tsv

    # Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.${key}.${category}.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.${key}.${category}.vcf.gz)
    """
}
