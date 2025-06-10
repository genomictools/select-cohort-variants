process AGGREGATE {
    tag "${pheno}:${key}:${category}"

    label 'simple'

    container params.rocker

    publishDir("${params.output_dir}/aggregate", mode: 'copy')

    input:
    tuple val(pheno), val(key), val(category),
          val(rlist), path(rlist_file), path(rlist_log),
          val(variable), path(annotations)

    output:
    tuple val(pheno), val(key), val(category), val("aggregate"),
          path("${pheno}.${key}.${category}.aggregate.tsv")
 
    script:
    """
    #!/bin/bash
	aggregate_genotyeps.R ${annotations} ${rlist_file} ${pheno}.${key}.${category}.aggregate.tsv
    """
}