process CONVERT {
    tag "${cohort}:${key}:${category}"

    label 'simple'
    label 'plink'

    publishDir("${params.output_dir}/plinked", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(category),
          path(file), path(index),
          val(n_samples), val(n_variants),
          path(phenotype)

    output:
    tuple val(cohort), val(key), val(category),
          path("${cohort}.${key}.${category}.bim"),
          path("${cohort}.${key}.${category}.bed"),
          path("${cohort}.${key}.${category}.fam"),
          path("${cohort}.${key}.${category}.nosex"),
          path("${cohort}.${key}.${category}.log")

    script:
    """
    #!/bin/bash
    plink \
        --vcf ${file} \
        --make-bed \
        --pheno <(awk '{print \$1, \$2, \$6}' ${phenotype}) \
        --double-id \
        --out ${cohort}.${key}.${category}
    """
}
