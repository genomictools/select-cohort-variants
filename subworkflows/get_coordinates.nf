#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { COORDINATES } from '../modules/coordinates.nf'

def tileBed(bed, chunk) {
    bed
        | splitCsv(sep: '\t')
        | flatMap { cohort, key, row -> 
            // Read bed file
            def chrom = row[0]
            def start = row[1].toInteger()
            def end   = row[2].toInteger()

            // New varibles
            def tiles = []
            def chunkStart = start

            // Tile by params.chunk size
            while (chunkStart <= end) {
                // Get chunk end
                def chunkEnd = Math.min(chunkStart + chunk - 1, end)
                def tileKey = "${chrom}:${chunkStart}-${chunkEnd}"
                
                // Write to bed file
                def outBedFile = "${cohort}.${tileKey}.tiled.bed"
                def writer = new File(outBedFile).newPrintWriter()
                writer.println([chrom, chunkStart, chunkEnd].join('\t'))
                writer.close()

                // Return tile record
                tiles << [ cohort, tileKey, file(outBedFile) ]

                // Update chunk start for next iteration
                chunkStart = chunkEnd + 1
            }
            return tiles 
        }
}

workflow get_coordinates {
    take:
    coords
    genome
    style
    
    main:
    COORDINATES(coords, genome, style)
        | transpose
        | set { bed }

    if ( params.coding ) {
        bed
            | collectFile { it -> [ "${it.first()}.bed", it.last() ] } 
            | map { [ it.simpleName, it ] }
            | splitText(
                by: params.chunk.toInteger(),
                file: 'chunk'
            )
            | map { [ it.first(), it.last().fileName, it.last() ] }
            | set { chunks }
    } else {
        tileBed(bed, params.chunk.toInteger())
            | set { chunks }
    }
    chunks | count | view
    emit:
    bed    = bed
    chunks = chunks
}

workflow  {
    genes_coords_ch = Channel.fromPath(params.cohorts)
        | splitCsv(header: true, sep: ',')
        | map { row -> [ cohort: row.cohort, chrom: row.chrom, start: row.start, end: row.end ] }
        | map { it -> 
            chrom = it.chrom ?: (1..2).collect { "chr$it" } + ['chrX', 'chrY']
            key   = (it.start && it.end) ? "${chrom}:${it.start}-${it.end}" : chrom
            [ it.cohort, key, chrom, it.start ?: null, it.end ?: null]
        }
        | transpose
        | unique
        | groupTuple(by: [1,2,3,4])
    
    get_coordinates( genes_coords_ch, params.genome, params.style )
}
