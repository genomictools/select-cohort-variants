process COMBINE {
    tag "${pheno}"

    label 'simple'

    container params.bcftools

    publishDir("${params.output_dir}/combined/", mode: 'copy')

    input:
    tuple val(pheno), val(chrom),
          path(file), path(index), val(n_vars)

    output:
    tuple val(pheno),
          path("${pheno}.combined.vcf.gz"),
          path("${pheno}.combined.vcf.gz.tbi"),
          env(n_vars)
        
    script:
    """
    #!/bin/bash
    # Combine vcfs and update IDs
    bcftools concat --naive ${file} | \
    bcftools annotate --set-id '%CHROM:%POS:%REF:%ALT' | \
    bcftools view --threads ${task.cpu} -Oz -o ${pheno}.combined.vcf.gz
    
    # Index the vcf
    tabix ${pheno}.combined.vcf.gz

	# Count the number of variants
    n_vars=\$(bcftools index -n ${pheno}.combined.vcf.gz)
	"""
}
