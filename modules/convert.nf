process CONVERT {
    tag "${pheno}:${key}:${category}"

    label 'simple'

    container = params.plink

    publishDir("${params.output_dir}/plinked", mode: 'copy')

    input:
    tuple val(pheno), val(key), val(category),
          path(file), path(index), val(n_vars)

    output:
    tuple val(pheno), val(key), val(category),
          path("${pheno}.${key}.${category}.bim"),
          path("${pheno}.${key}.${category}.bed"),
          path("${pheno}.${key}.${category}.fam"),
          path("${pheno}.${key}.${category}.nosex"),
          path("${pheno}.${key}.${category}.log")

    script:
    """
    #!/bin/bash
    plink \
        --vcf ${file} \
        --make-bed \
        --const-fid 0 \
        --out ${pheno}.${key}.${category}
    """
}
