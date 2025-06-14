process AGGREGATE {
    tag "${cohort}:${key}:${category}"

    label 'simple'
    label 'rocker'

    publishDir("${params.output_dir}/aggregate", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(category),
          val(rlist), path(rlist_file), path(rlist_log),
          val(variable), path(annotations)

    output:
    tuple val(cohort), val(key), val(category), val("aggregate"),
          path("${cohort}.${key}.${category}.aggregate.tsv")
 
    script:
    """
    #!/bin/bash
	aggregate_genotyeps.R ${annotations} ${rlist_file} ${cohort}.${key}.${category}.aggregate.tsv
    """
}