#!/bin/bash

#SBATCH -o tests/tests.out
#SBATCH -e tests/tests.err
#SBATCH -J tests
#SBATCH -p master-worker
#SBATCH -t 120:00:00

# Setup test directory
mkdir -p tests/

TESTDATA="git@github.com:genomictools/test-datasets.git"
BRANCH="select-cohort-variants"
SRC="tests/input"

git -C $SRC pull || \
git clone -b $BRANCH $TESTDATA $SRC

# Run nextflow
module load Nextflow

# Run nextflow (example)
# nextflow run genomictools/select-cohort-variants -r main \
cd tests/

nextflow run ../main.nf \
    --output_dir ./results/ \
    -profile local,test \
    -resume
