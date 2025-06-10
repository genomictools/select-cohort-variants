#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { SUBSET }      from '../modules/subset.nf'
include { COMBINE }     from '../modules/combine.nf'

workflow get_cohort {
    take:
    cohorts
    bed

    main:
    bed
        | transpose
        | combine(cohorts, by: [0,1])
        | SUBSET
        | filter { it.last().toInteger() > 0 }
        | groupTuple(by: [0,2])
        | COMBINE

    emit:
    variants = COMBINE.out
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
