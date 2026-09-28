process TABULATE {
    tag "${cohort}:${key}:${category}"

    label 'simple'
    label 'bcftools'

    publishDir("${params.output_dir}/variants", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(category),
          path(file), path(index),
          val(n_samples), val(n_variants)

    output:
    tuple val(cohort), val(key), val(category),
          path("${cohort}.${key}.${category}.tsv")

    script:
    """
    #!/bin/bash
    # Get frequency
    bcftools +split-vep \
        -a ${params.vep_tag} \
        -c Gene \
        -s worst \
        -f '%Gene\t%CHROM:%POS:%REF:%ALT\t%AC_nfe\t%AN_nfe\t%AF_nfe\t%nhomalt_nfe\n' \
        ${file} \
        > ${cohort}.${key}.${category}.tsv
    """
}
