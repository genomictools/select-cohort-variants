#!/bin/bash

#SBATCH -o tests/tests.out
#SBATCH -e tests/tests.err
#SBATCH -J tests
#SBATCH -p master-worker
#SBATCH -t 120:00:00

# Load conda environment
module load Java/17
source $NXF_CONDA

# # Setup tests
# curl -fsSL https://get.nf-test.com | bash
# ./nf-test init
# ./nf-test generate pipeline main.nf

# # Download input data
# mkdir -p tests tests/input
# URL="https://figshare.com/ndownloader/files"
# wget -c $URL/50487621 -O tests/input/pheno.variants.vcf.gz
# wget -c $URL/50487624 -O tests/input/pheno.variants.vcf.gz.tbi
# wget -c $URL/50385591 -O tests/input/pheno.cases.txt

# # Create input file
# echo "cohort,chrom,start,end,file,index,samples" > input/cohorts_input.csv
# echo "pheno1,,,,$PWD/tests/input/pheno.variants.vcf.gz,$PWD/tests/input/pheno.variants.vcf.gz.tbi,$PWD/tests/input/pheno.cases.txt" >> input/cohorts_input.csv
# echo "pheno2,chr2,,,$PWD/tests/input/pheno.variants.vcf.gz,$PWD/tests/input/pheno.variants.vcf.gz.tbi,$PWD/tests/input/pheno.cases.txt" >> input/cohorts_input.csv
# echo "pheno3,chr3,,,$PWD/tests/input/pheno.variants.vcf.gz,$PWD/tests/input/pheno.variants.vcf.gz.tbi,$PWD/tests/input/pheno.cases.txt" >> input/cohorts_input.csv
# echo "pheno4,chr3,1,20000000,$PWD/tests/input/pheno.variants.vcf.gz,$PWD/tests/input/pheno.variants.vcf.gz.tbi,$PWD/tests/input/pheno.cases.txt" >> input/cohorts_input.csv

# Run tests
./nf-test test tests/main.nf.test

# Run nextflow (example)
# nextflow run genomictools/select-cohort-variants -r main \
nextflow run ../main.nf \
    --output_dir ./results/ \
    -profile local,test \
    -resume
