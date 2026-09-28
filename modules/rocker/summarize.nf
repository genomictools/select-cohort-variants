process SUMMARIZE {
    tag "${cohort}:${key}:${category}"

    label 'simple'
    label 'rocker'

    publishDir("${params.output_dir}/summary", mode: 'copy')

    input:
    tuple val(cohort), val(key), val(category), path(file)

    output:
    tuple val(cohort), val(category),
          path("${cohort}.${category}.summary.tsv")

    script:
    """
    #!/bin/bash
    #!/bin/bash
    echo -e "gene\tnvar\tac\tan\taf\tnhom" > ${cohort}.${category}.summary.tsv
    cat ${file} | \
    sort -u | \
    awk '
    {
        key = \$1
        count[key][\$2]++
        for (i = 3; i <= NF; i++) {
            sum[key][i] += \$i
        }
    }
    END {
        for (key in sum) {
            printf "%s\t", key
            unique_count = length(count[key])
            printf "%d\t", unique_count
            for (i = 3; i <= NF; i++) {
                if (sum[key][i] == int(sum[key][i])) {
                    printf "%d\t", sum[key][i]
                } else {
                    printf "%f\t", sum[key][i]
                }
            }
            printf "\\n"
        }
    }
    ' \
    >> ${cohort}.${category}.summary.tsv
    """
}
