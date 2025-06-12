#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { SUBSET }      from '../modules/subset.nf'
include { COMBINE }     from '../modules/combine.nf'

workflow get_cohort {
    take:
    cohorts
    bed

    main:
    cohorts
        | combine(bed, by: 0)
        | SUBSET        
        | filter { it.last().toInteger() > 0 }
        | groupTuple(by: 0)
        | COMBINE
        | filter { it.last().toInteger() > 0 }
        | set { variants}

    emit:
    variants
}

workflow  {
    cohorts_ch = Channel.fromPath(params.cohorts)
        | splitCsv(header: true, sep: ',')
        | map { row -> [ row.cohort, row.chrom, file(row.file), file(row.index), file(row.samples)] }

    coordinates_ch = Channel.fromPath(params.cohorts)
        | splitCsv(header: true, sep: ',')
        | map { row -> [ row.cohort, row.chrom, row.file ] }

    get_cohort( cohorts, coordinates_ch )
}
