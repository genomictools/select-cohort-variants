process EXTRACT {
    tag "${cohort}:${key}:${category}:${variable}"

    label 'simple'
	label 'plink'

    publishDir("${params.output_dir}/variants", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(category),
          path(bim), path(bed), path(fam), path(nosex), path(log),
		  val(variable)

    output:
    tuple val(cohort), val(key), val(category), val(variable),
	      path("${cohort}.${key}.${category}.extracted.${variable}"),
	      path("${cohort}.${key}.${category}.extracted.log")

    script:
    if ( variable == 'list' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --recode list --out ${cohort}.${key}.${category}.extracted
		"""
    } else if ( variable == 'rlist' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --recode rlist --out ${cohort}.${key}.${category}.extracted
		"""
    } else if ( variable == 'snplist' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --write-snplist --out ${cohort}.${key}.${category}.extracted
		"""
    } else if ( variable == 'frqx' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --freqx --out ${cohort}.${key}.${category}.extracted
		"""
    } else {
		println "Variable ${variable} not recognized"
	}
}
