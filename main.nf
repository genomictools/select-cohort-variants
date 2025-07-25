#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Load subworkflow
include { get_coordinates } from './subworkflows/get_coordinates.nf'
include { get_cohort }      from './subworkflows/get_cohort.nf'
include { select_variants } from './subworkflows/select_variants.nf'
include { summarize_cases } from './subworkflows/summarize_cases.nf'
include { summarize_controls } from './subworkflows/summarize_controls.nf'

// Define input channels
cohorts_ch = Channel.fromPath(params.cohorts)
    | splitCsv(header: true, sep: ',')
    | map { row -> [
        row.cohort,
        file(row.file), file(row.index),
        file(row.pedigree)
    ] }
    | unique

pedigree_ch = Channel.fromPath(params.cohorts)
    | splitCsv(header: true, sep: ',')
    | map { row -> [ row.cohort, file(row.pedigree) ] }
    | unique

genes_coords_ch = Channel.fromPath(params.cohorts)
    | splitCsv(header: true, sep: ',')
    | map { row -> [ cohort: row.cohort, chrom: row.chrom, start: row.start, end: row.end, genelist: row.genelist ] }
    | map { it -> 
        chrom = it.chrom ?: (1..22).collect { "chr$it" } + ['chrX', 'chrY']
        key   = (it.start && it.end) ? "${chrom}:${it.start}-${it.end}" : chrom

        [ it.cohort, key, chrom, it.start ?: null, it.end ?: null, it.genelist ? file(it.genelist) : null ]
    }
    | transpose
    | unique
    | groupTuple(by: [1,2,3,4,5])

category_ch = Channel.of(params.categories.split(','))
// 'Pathogenic,Damaging,Splicing,High,PTV,Stop,Rare'

variable_ch = Channel.of(params.variables.split(','))
// 'rlist,snplist,frqx,frq.strat,frq.cc,frq.counts' 

// Run the main workflow
workflow  {
    coordinates = get_coordinates( genes_coords_ch, params.genome, params.style )
    cohorts = get_cohort( cohorts_ch, coordinates.bed )
    variants = select_variants( cohorts.variants, coordinates.chunks )

    if ( params.cohort_type == 'cases' ) {
    summary = summarize_cases( variants.genotypes, pedigree_ch, variants.annotations )

    summary
        | filter { it[3] == 'snplist' || it[3] == 'rlist'}
        // | take (1) | view
        | collectFile (
            storeDir: "${params.output_dir}/summary",
        )
        { it -> [ "${it[0]}.${it[2]}.${it[3]}.tsv", it[4] ] }

    summary
        | filter { it[3] != 'snplist' && it[3] != 'rlist'}
        | collectFile (
            keepHeader: true,
            storeDir: "${params.output_dir}/summary",
        )
        { it -> [ "${it[0]}.${it[2]}.${it[3]}.tsv", it[4] ] }
    } else if ( params.cohort_type == 'controls' ) {
    summary = summarize_controls( variants.genotypes, variants.annotations )
    summary | view
    } else {
        error "Invalid cohort type: ${params.cohort_type}. Expected 'cases' or 'controls'."
    }
}
