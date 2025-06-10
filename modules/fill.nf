process FILL {
    tag "${pheno}:${key}"

    label 'simple'

    container params.bcftools

    publishDir("${params.output_dir}/filled", mode: 'symlink')

    input:
    tuple val(pheno), path(file), path(index), val(n_vars),
          val(key), path(coordinates)

    output:
    tuple val(pheno),
          path("${pheno}.${key}.filled.vcf.gz"),
          path("${pheno}.${key}.filled.vcf.gz.tbi"),
		  env(n_vars),
          val(key), path(coordinates)

    script:
    """
    #!/bin/bash
    # Fill in genotypes
    bcftools view -R ${coordinates} ${file} | \
    bcftools +setGT -- -t q -n 0 -i 'FMT/GQ < ${params.GQ} | FMT/DP < ${params.DP} | VAF < ${params.VAF}' | \
    bcftools +fill-tags -- -t all | \
    bcftools view -g het --threads ${task.cpu} -Oz -o ${pheno}.${key}.filled.vcf.gz

	# Index the filled VCF
    tabix ${pheno}.${key}.filled.vcf.gz

    # Count the number of variants
    n_vars=\$(bcftools index -n ${pheno}.${key}.filled.vcf.gz)
    """
}
