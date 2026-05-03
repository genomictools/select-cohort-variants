#!/bin/bash

#SBATCH -o tests/tests.out
#SBATCH -e tests/tests.err
#SBATCH -J tests
#SBATCH -p master-worker
#SBATCH -t 120:00:00

# Setup tests
# curl -fsSL https://get.nf-test.com | bash
# ./nf-test init
# ./nf-test generate pipeline main.nf

# Setup test directory
mkdir -p tests/

TESTDATA="git@github.com:genomictools/test-datasets.git"
BRANCH="select-cohort-variants"
SRC="tests/input"

git -C $SRC pull || \
git clone -b $BRANCH $TESTDATA $SRC

# Run nextflow
module load Nextflow

cd tests/
# Run tests
# ./nf-test test tests/main.nf.test

# Run nextflow (example)
# nextflow run genomictools/select-cohort-variants -r main \
cd tests/
nextflow run ../main.nf \
    --output_dir ./results/ \
    -profile local,test_annotate \
    -resume
