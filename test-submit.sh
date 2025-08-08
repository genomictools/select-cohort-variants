#!/bin/bash

#SBATCH -o tests/tests.out
#SBATCH -e tests/tests.err
#SBATCH -J tests
#SBATCH -p master-worker
#SBATCH -t 120:00:00

# Load conda environment
module load Java/17
source $NXF_CONDA

# Setup tests
# curl -fsSL https://get.nf-test.com | bash
# ./nf-test init
# ./nf-test generate pipeline main.nf

# # Download input data
mkdir -p tests tests/input

URL="https://raw.githubusercontent.com/genomictools/test-datasets/refs/heads/select-cohort-variants"
wget -c $URL/cohorts_input.csv -O tests/input/cohorts_input.csv
wget -c $URL/cohorts_input_annotate.csv -O tests/input/cohorts_input_annotate.csv

wget -c $URL/pheno.ped -O tests/input/pheno.ped
wget -c $URL/FAM01.ped -O tests/input/FAM01.ped
wget -c $URL/FAM02.ped -O tests/input/FAM02.ped
wget -c $URL/FAM03.ped -O tests/input/FAM03.ped

wget -c $URL/empty.genelist.txt -O tests/input/empty.genelist.txt
wget -c $URL/genelist.txt -O tests/input/genelist.txt


wget -c $URL/pheno.variants.vcf.gz -O tests/input/pheno.variants.vcf.gz
wget -c $URL/pheno.variants.vcf.gz.tbi -O tests/input/pheno.variants.vcf.gz.tbi

wget -c $URL/families.variants.vcf.gz -O tests/input/families.variants.vcf.gz
wget -c $URL/families.variants.vcf.gz.tbi -O tests/input/families.variants.vcf.gz.tbi

wget -c $URL/pheno.variants.anno.vcf.gz -O tests/input/pheno.variants.anno.vcf.gz
wget -c $URL/pheno.variants.anno.vcf.gz.tbi -O tests/input/pheno.variants.anno.vcf.gz.tbi
wget -c $URL/pheno.variants.novep.vcf.gz -O tests/input/pheno.variants.novep.vcf.gz
wget -c $URL/pheno.variants.novep.vcf.gz.tbi -O tests/input/pheno.variants.novep.vcf.gz.tbi

# Run tests
# ./nf-test test tests/main.nf.test

# Run nextflow (example)
# nextflow run genomictools/select-cohort-variants -r main \
cd tests/
nextflow run ../main.nf \
    --output_dir ./results/ \
    -profile local,test_annotate \
    -resume
