process COORDINATES {
    tag "${key}:${genome}:${style}"

    label 'simple'

    container params.bioconductor

    publishDir("${params.output_dir}/coordiantes", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(chrom), val(start), val(end)
    val(genome)
    val(style)

    output:
    tuple val(cohort), val("${key}"), path("${key}.bed")

    script:
    """
    #!/bin/bash
    generate_coordinates.R ${chrom} ${start} ${end} ${genome} ${style} ${params.coding} ${key}.bed
    """
}
