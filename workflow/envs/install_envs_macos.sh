#!/bin/bash

set -e
set -u
set -o

echo "--------creating qiime environment"
## conda update conda
## conda install wget
## make sure that the qiime installation that you have in here is for the proper software system!! 
## these instructions are for apple silicon (M1 and M2 chips)
wget https://data.qiime2.org/distro/core/qiime2-2023.5-py38-osx-conda.yml
CONDA_SUBDIR=osx-64 conda env create -n qiime2-2023.5 --file qiime2-2023.5-py38-osx-conda.yml
conda config --env --set subdir osx-64
rm qiime2-2023.5-py38-osx-conda.yml
pip install snakemake

echo "--------creating R envrionment"
conda env create -f r_env.yml
