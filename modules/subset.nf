process SUBSET {
    tag "${cohort}:${key}"

    label 'simple'

    container params.bcftools

    publishDir("${params.output_dir}/subsets", mode: 'copy')

    input:
    tuple val(cohort), path(file), path(index), path(samples),
          val(key), path(coordinates)

    output:
    tuple val(cohort), val(key),
          path("${cohort}.${key}.subset.vcf.gz"),
          path("${cohort}.${key}.subset.vcf.gz.tbi"),
          env(n_samples),
          env(n_variants)

    script:
    """
    #!/bin/bash
    # Subset cohort
    bcftools view -R ${coordinates} -S ${samples} ${file} | \
    if [ ${params.normalize} ];      then bcftools norm -m -any; fi | \
    if [ ${params.pass} ];           then bcftools view -i 'FILTER="PASS"'; fi | \
    if [ ${params.missing_as_ref} ]; then bcftools +setGT -- -t . -n 0; fi | \
    bcftools +fill-tags -- -t all | \
    bcftools view -g het --threads ${task.cpus} -Oz -o ${cohort}.${key}.subset.vcf.gz

    # Index the VCF
    tabix ${cohort}.${key}.subset.vcf.gz

    # Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.${key}.subset.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.${key}.subset.vcf.gz)
    """
}
