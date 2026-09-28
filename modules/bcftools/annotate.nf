process ANNOTATE {
    tag "${cohort}:${key}"

    label 'simple'
	label 'bcftools'

    publishDir("${params.output_dir}/annotated", mode: 'copy')

    input:
    tuple val(cohort), val(key),
          path(file), path(index), 
          val(n_samples), val(n_variants),
          path(annot_file), path(annot_index)

    output:
    tuple val(cohort), val(key),
          path("${cohort}.${key}.annotated.vcf.gz"),
          path("${cohort}.${key}.annotated.vcf.gz.tbi"),
          env(n_samples),
          env(n_variants)

    script:
    """
    #!/bin/bash
    # Subset cohort
    bcftools annotate \
        -a ${annot_file} \
        -c INFO/${params.vep_tag} \
        -h <(bcftools view -h ${annot_file} | grep ${params.vep_tag}) \
        ${file} \
        --threads ${task.cpus} \
        -Oz -o ${cohort}.${key}.annotated.vcf.gz

    # Index the VCF
    tabix ${cohort}.${key}.annotated.vcf.gz

    # Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.${key}.annotated.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.${key}.annotated.vcf.gz)
    """
}
