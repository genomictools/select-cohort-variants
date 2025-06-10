process FILTER {
    tag "${pheno}:${key}:${category}"

    label 'simple'

    container params.bcftools

    publishDir("${params.output_dir}/filtered/", mode: 'copy')

    input:
    tuple val(pheno), path(file), path(index), val(n_vars),
          val(key), path(coordinates),
          val(category)

    output:
    tuple val(pheno), val(key), val(category),
          path("${pheno}.${key}.${category}.vcf.gz"),
          path("${pheno}.${key}.${category}.vcf.gz.tbi"),
          path("${pheno}.${key}.${category}.annotations.tsv"),
          env(n_vars)
        
    script:
    """
    #!/bin/bash
    # Filter variants
    bcftools view -e "MAF > ${params.MAF} || HWE < ${params.HWE} || ExcHet < ${params.ExcHet}" ${file} | \
    bcftools +split-vep -s worst -c CLIN_SIG -e "CLIN_SIG ~ 'conflicting' || CLIN_SIG ~ 'benign'" | \
    if   [ ${category} == 'Pathogenic' ]; then bcftools +split-vep -s worst -c CLIN_SIG -i "CLIN_SIG ~ 'pathogenic' || CLIN_SIG ~ 'likely_pathogenic'";
    elif [ ${category} == 'Rare' ];       then bcftools +split-vep -s worst -c ${params.AF_COL}:Float,MAX_AF:Float -e "${params.AF_COL} > ${params.gnomADe_AF} || MAX_AF > ${params.gnomADe_AF}";
    elif [ ${category} == 'High' ];       then bcftools +split-vep -s worst -c IMPACT,CADD_PHRED:Float -i "IMPACT='HIGH' && CADD_PHRED > ${params.CADD}";
    elif [ ${category} == 'Damaging' ];   then bcftools +split-vep -s worst -c IMPACT,CADD_PHRED:Float -i "(IMPACT='HIGH' || IMPACT='MODERATE') && CADD_PHRED > ${params.CADD}";
    elif [ ${category} == 'PTV' ];        then bcftools +split-vep -s worst -c Consequence -i "Consequence~'stop_gained' || Consequence~'frameshift_variant' || Consequence~'splice_acceptor_variant'";
    elif [ ${category} == 'Stop' ];       then bcftools +split-vep -s worst -c Consequence -i "Consequence~'stop_gained'";
    elif [ ${category} == 'Splicing' ];   then bcftools +split-vep -s worst -c SpliceAI_pred_DS_AG:Float,SpliceAI_pred_DS_AL:Float,SpliceAI_pred_DS_DG:Float,SpliceAI_pred_DS_DL:Float -i "SpliceAI_pred_DS_AG > ${params.DS} || SpliceAI_pred_DS_AL > ${params.DS} || SpliceAI_pred_DS_DG > ${params.DS} || SpliceAI_pred_DS_DL > ${params.DS}";
    else exit "Category: ${category} is not recognized"; fi | \
    bcftools annotate --set-id '%CHROM:%POS:%REF:%ALT' | \
    bcftools view --threads ${task.cpus} -Oz -o ${pheno}.${key}.${category}.vcf.gz

    # Index the VCF
    tabix ${pheno}.${key}.${category}.vcf.gz

	# Extract annotations
	bcftools +split-vep \
		-s worst \
		-c Gene \
		-f '%CHROM:%POS:%REF:%ALT\t%Gene\t%CSQ\n' \
		-d -A tab \
		${pheno}.${key}.${category}.vcf.gz \
		> ${pheno}.${key}.${category}.annotations.tsv

    # Count the number of variants
    n_vars=\$(bcftools index -n ${pheno}.${key}.${category}.vcf.gz)
    """
}
