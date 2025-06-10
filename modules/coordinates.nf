process COORDINATES {
    tag "${chrom}"

    label 'simple'

    container params.bioconductor

    publishDir("${params.output_dir}/coordiantes", mode: 'copy')

    input:
    tuple val(cohort), val(chrom)
    val(genome)
    val(style)

    output:
    tuple val(cohort), val(chrom), path("${chrom}.bed")
 
    script:
    """
    #!/bin/bash
    generate_coordinates.R ${genome} ${style} ${chrom} ${params.coding} ${chrom}.bed
    """
}
