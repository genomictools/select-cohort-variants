process EXTRACT {
    tag "${pheno}:${key}:${category}:${variable}"

    label 'simple'

    container params.plink

    publishDir("${params.output_dir}/variants", mode: 'copy')

    input:
    tuple val(pheno), val(key), val(category),
          path(bim), path(bed), path(fam), path(nosex), path(log),
		  val(variable)

    output:
    tuple val(pheno), val(key), val(category), val(variable),
	      path("${pheno}.${key}.${category}.extracted.${variable}"),
	      path("${pheno}.${key}.${category}.extracted.log")

    script:
    if ( variable == 'list' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --recode list --out ${pheno}.${key}.${category}.extracted
		"""
    } else if ( variable == 'rlist' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --recode rlist --out ${pheno}.${key}.${category}.extracted
		"""
    } else if ( variable == 'snplist' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --write-snplist --out ${pheno}.${key}.${category}.extracted
		"""
    } else if ( variable == 'frqx' ) {
		"""
		#!/bin/bash
		plink --bfile ${bim.baseName} --freqx --out ${pheno}.${key}.${category}.extracted
		"""
    } else {
		println "Variable ${variable} not recognized"
	}
}
