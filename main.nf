#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Load subworkflow
include { get_coordinates } from './subworkflows/get_coordinates.nf'
include { get_cohort }      from './subworkflows/get_cohort.nf'
include { select_variants } from './subworkflows/select_variants.nf'
include { summarize_genes } from './subworkflows/summarize_genes.nf'

// Define input channels
cohorts_ch = Channel.fromPath(params.cohorts)
    | splitCsv(header: true, sep: ',')
    | map { row -> [
        row.cohort,
        row.chrom ?: (1..22).collect { "chr$it" } + ['chrX', 'chrY'],
        file(row.file), file(row.index),
        file(row.samples)
    ] }
    | transpose

genes_coords_ch = Channel.fromPath(params.cohorts)
    | splitCsv(header: true, sep: ',')
    | map { row -> [ 
        row.cohort,
        row.chrom ?: (1..22).collect { "chr$it" } + ['chrX', 'chrY']
    ] }
    | transpose
    | groupTuple(by: [1,2,3])

category_ch = Channel.of(params.categories.split(','))
variable_ch = Channel.of( 'rlist', 'snplist', 'frqx' )

// Run the main workflow
workflow  {
    coordinates = get_coordinates( genes_coords_ch, params.genome, params.style )
    cohorts = get_cohort( cohorts_ch, coordinates.bed )
    variants = select_variants( cohorts.variants, coordinates.chunks )
    summary = summarize_genes( variants.genotypes, variants.annotations )

    summary
        | collectFile (
            keepHeader: true,
            storeDir: "${params.output_dir}/summary",
        )
        { it -> [ "${it[0]}.${it[2]}.${it[3]}.tsv", it[4] ] }
}
