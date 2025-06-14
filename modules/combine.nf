process COMBINE {
    tag "${cohort}"

    label 'simple'
    label 'bcftools'

    publishDir("${params.output_dir}/combined/", mode: 'copy')

    input:
    tuple val(cohort), val(key),
          path(file), path(index),
          val(n_samples),
          val(n_variants)

    output:
    tuple val(cohort),
          path("${cohort}.combined.vcf.gz"),
          path("${cohort}.combined.vcf.gz.tbi"),
          env(n_samples),
          env(n_variants)

    script:
    """
    #!/bin/bash
    # Combine vcfs and update IDs
    bcftools concat --naive ${file} | \
    bcftools annotate --set-id '%CHROM:%POS:%REF:%ALT' | \
    bcftools view --threads ${task.cpus} -Oz -o ${cohort}.combined.vcf.gz
    
    # Index the vcf
    tabix ${cohort}.combined.vcf.gz

	# Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.combined.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.combined.vcf.gz)
	"""
}
