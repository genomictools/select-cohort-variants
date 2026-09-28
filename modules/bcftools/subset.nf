process SUBSETMULTIVCF {
    tag "${cohort}:${key}"

    label 'simple'
	label 'bcftools'

    publishDir("${params.output_dir}/subsets", mode: 'copy')

    input:
    tuple val(cohort), path(file), path(index), path(pedigree),
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
    # Get sample names from pedigree file
    if [ "${params.family_id}" = "true" ]; then
        awk '{print \$1"_"\$2}' ${pedigree} > samples.txt
    else
        awk '{print \$2}' ${pedigree} > samples.txt
    fi
    # Subset cohort
    bcftools view -R ${coordinates} -S samples.txt --force-samples ${file} | \
    if [ "${params.normalize}" = "true" ];      then bcftools norm -m -any; fi | \
    if [ "${params.pass}" = "true" ];           then bcftools view -i 'FILTER="PASS"'; fi | \
    if [ "${params.missing_as_ref}" = "true" ]; then bcftools +setGT -- -t . -n 0; fi | \
    bcftools +fill-tags -- -t all | \
    bcftools view -g het --threads ${task.cpus} -Oz -o ${cohort}.${key}.subset.vcf.gz

    # Index the VCF
    tabix ${cohort}.${key}.subset.vcf.gz

    # Count the number of samples and variants
    n_samples=\$(bcftools  query -l ${cohort}.${key}.subset.vcf.gz | wc -l)
    n_variants=\$(bcftools index -n ${cohort}.${key}.subset.vcf.gz)
    """
}

process SUBSETSINGLEVCF {
    tag "${cohort}:${key}:${sample}:${sample_type}"

    label 'simple'
    label 'bcftools'

    publishDir("${params.output_dir}/subsets", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(sample), val(sample_type),
		  path(vcf), path(vcf_index)

    output:
    tuple val(cohort), val(key), val(sample), val(sample_type),
          path("${cohort}.${key}.${sample}.${sample_type}.vcf.gz"),
          path("${cohort}.${key}.${sample}.${sample_type}.vcf.gz.tbi"),
          env(n_variants)

    script:
    """
    #!/bin/bash
    bcftools view -r ${key} ${vcf} --threads ${task.cpus} -Oz -o ${cohort}.${key}.${sample}.${sample_type}.vcf.gz
    tabix ${cohort}.${key}.${sample}.${sample_type}.vcf.gz
    n_variants=\$(bcftools index -n ${cohort}.${key}.${sample}.${sample_type}.vcf.gz)
    """
}
