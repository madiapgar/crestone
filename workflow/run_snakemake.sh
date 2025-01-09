#!/bin/bash

## my command to run my snakemake workflow bc I'm lazy
## this is an edit yay
snakemake \
    -s workflow/snakefile \
    -c 7 \
    --use-conda \
    --keep-going \
    --configfile workflow/config_files/config_template.yml