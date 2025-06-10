#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { COORDINATES } from '../modules/coordinates.nf'

workflow get_coordinates {
    take:
    coords
    genome
    style
    
    main:
    COORDINATES(coords, genome, style)
        | transpose
        | collectFile { it -> [ "${it.first()}.bed", it.last() ] } 
        | map { [ it.simpleName, it ] }
        | splitText(
            by: params.chunk.toInteger(),
            file: 'chunk'
        )
        | map { [ it.first(), it.last().fileName, it.last() ] }
        | set { chunks }

    emit:
    bed    = COORDINATES.out
    chunks = chunks
}

workflow  {
    genes_coords_ch = Channel.fromPath(params.cohorts)
        | splitCsv(header: true, sep: ',')
        | map { row -> [ row.cohort, row.chrom ] }
        | transpose
        | groupTuple(by: [1,2,3])
    
    get_coordinates( genes_coords, params.genome, params.style )
}
