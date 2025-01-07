# **Running Madi's 16S Sequencing Microbiome Profiling Data Analysis Workflow!**

## **Introduction**

I initially wrote this workflow to help myself out with 16S data analysis for a gut microbiome study I worked on for my graduate thesis.
Since then, it has proven helpful in subsequent 16S data analysis projects for myself and others, so I decided to put together a quick
tutorial on how to use it! 

This workflow can take raw 16S sequencing FASTA files and run them through QIIME2 mirobiome profiling software to return alpha and beta diversity measures and taxa barcharts. While users can just directly use QIIME2 for their 16S analysis, I've found this workflow incredibly helpful when analyzing multiple sequencing runs and in the case of human error, which I'm extremely prone to, rerunning the analysis. 

*Disclaimer: While I am actively working on improving my workflow and making it more user-friendly, I reccommend that those who want to use it in it's current state have some amount of bioinformatics/software experience and be familiar with typical microbiome profiling analysis.* 

## **Workflow Options**

There are a few different places that you can start and stop my workflow depending on which parts of the 16S data analysis you need done:

1. You can run the analysis from start to finish, raw FASTA sequencing files through alpha/beta diversity.
    - via all global options in the config file being set to **"yes"**
2. You can run Demux and DADA2 separately so you can check the demultiplexed results for where to trim/truncate your sequences in DADA2.
    - via `raw_sequences:`**"no"** and `run_demux_only`/`run_dada2_only`:**"yes"/"no"** in the config file
3. You can come into the analysis with BIOM table and representative sequences .qza files and run taxonomic classification/core metrics analysis from there.
    - via `raw_sequences`, `run_demux_only`, and `run_dada2_only`:**"no"** in the config file
    - via `tax_class` and `core_metrics`:**"yes"** in the config file
    - make sure that you include the file paths to your BIOM table and representative sequences under `biom_table`/`rep_seqs` in the config file
4. You can stop the workflow after taxonomic classification to determine your sampling depth for core metrics analysis. 
    - via `tax_class`:**"yes"** and `core_metrics`:**"no"** in the config file 
    - once you know your sampling depth and have updated `core_metrics_sampling_depth` in your config file, you can change `core_metrics:` **"yes"** and rerun the workflow 

If this seems all a little complicated, don't worry, we're going over the config file in more depth later. 

## **Tutorial**

If you've made it this far, congratulations, and I'm so sorry. In this tutorial, I will try my best to help you run my workflow on your 16S microbiome analysis!

### **Cloning the GitHub Repository**

Based on how my workflow is designed and best practices, cloning the GitHub repository that contains the workdlow will make your life easier. First, let's ensure that you have git installed locally. If you have git installed, when you type `git` into your console you should get the git help page printed to your screen. If not, nothing will come up, meaning that you'll need to install git. This [handy webpage](https://github.com/git-guides/install-git) provides additional information on how to install git locally. 

If you have macOS like I do, you can use `brew` to install git like so:

```bash
brew install git 
```

Once you have git installed locally, navigate to where you would like the cloned repository to live (this is usually in an easily accessible directory). It doesn't matter what you name the directory locally, GitHub doesn't track the overall directory name, just it's contents. Then, run the command below to clone the GitHub repository where the workflow lives. Doing so gives you access to the exact same files that I use to run the workflow. 

```bash
git clone https://github.com/madiapgar/crestone.git
```

So, after cloing the GitHub repository you should have a file system setup that looks something like this:

```bash
$ tree workflow
workflow
├── my_data
└── workflow
    ├── config_files
    │   ├── config_template.yml
    │   ├── example_rawSeqOnly_config.yml
    │   └── example_wBiomTable_config.yml
    ├── envs
    │   ├── install_envs_macos.sh
    │   └── r_env.yml
    ├── rules
    │   ├── 01_demux.smk
    │   ├── 02_dada2.smk
    │   ├── 03_phylogeny.smk
    │   └── 04_core_metrics.smk
    ├── run_snakemake.sh
    └── snakefile
```

**Next steps:**

1. Put the data that you want analyzed in the `my_data` directory. 


### **Installing snakemake and needed conda environments**

This workflow was written via Snakemake so you will first need to install it into a conda environment. I would reccommend creating a new conda environment for this installation so Snakemake is not installed into your base conda environment. 

```bash
## activating base conda environment if not activated already
conda activate base

## creating a conda environment named "snakemake_env" and directly installing snakemake into it
conda create -c conda-forge -c bioconda --name snakemake_env snakemake
```

If installing Snakemake via conda-forge and bioconda doesn't work out for you, you can install it via pip as well. Be warned, the Snakemake installation via pip doesn't have full capabilites (but will still work for running this workflow). 

```bash
## activating base conda environment if not activated already
conda activate base

## creating a new conda environment named "snakemake_env"
conda create --name snakemake_env

## activating the "snakemake_env" you just created
conda activate snakemake_env

## installing snakemake into this environment via pip
pip install snakemake
```

Since QIIME2 is used in this workflow, you will need to install a conda environment for it prior to running the workflow. Luckily for you, I have written `.yaml` files and a `bash` script for the conda environment installation which are under `workflow/envs`. QIIME2 has different installation instructions based on the OS of your local computer; Linux users will run the `install_envs_linux.sh` script and MacOS users will run the `install_envs_macos.sh` script. **If you already have QIIME2 installed on your computer, you can skip this step.**

```bash
## linux users
sh practice_workflow/workflow/envs/install_envs_linux.sh

## macos (apple silicon/arm64) users
sh practice_workflow/workflow/envs/install_envs_macos.sh
```

I currently do not have a `bash` script put together for Windows or non-Apple Silicon MacOS users but QIIME2 installation instructions for those operating systems can be found [here](https://docs.qiime2.org/2024.5/install/native/#install-qiime-2-within-a-conda-environment). 

Hopefully you have now successfully installed all needed conda environments to run the workflow! To double check, run the following code:

```bash
conda env list
```

Where you should see `snakemake_env` and `qiime2-2023.5` listed among your other conda environments.

### **Setting up your config file**

If you navigate to your `workflow/config_files` directory, you'll notice that I already put a `config_template.yml` file there. Let's open `config_template.yml` and take a look at it. 

*A note: Like any other software tool, my workflow is something that may need to be run multiple times with differing parameters in order to get to the end result you desire, it just depends on how complicated your data is. The config file is incredibly flexible and can be easily edited between runs to reflect new desired parameters or files so don't be afraid to switch things up!* 

```yaml
## config file template
## if you need additional examples for how to handle your config file, check out the workflow/config_files directory!

## the directory the data you're analyzing lives in (this should NOT be in the workflow directory) - in this case, it's your my_data directory
## you only have to name this once so all your subdirectories for raw sequencing files and metadata can be written as if you're already in my_data
dataset_dir: "my_data/"
qiime_env: "which QIIME2 environment did you install?"

## --GLOBAL OPTIONS--
## are you starting with raw 16S sequences?
raw_sequences: "no" ## options: yes and no 

## IF YOU HAVE SAID YES TO raw_sequences WHATEVER YOU PUT IN run_demux_only AND run_dada2_only WILL NOT MATTER
## option to split demux and dada2 steps so you can know where to trim/truncate your seqs
run_demux_only: "yes" ## options: yes and no
run_dada2_only: "no" ## options: yes and no

## do you want to run taxonomic classification? chances are yes since you're running this workflow
tax_class: "no" ## options: yes and no, default is yes 

## do you want to run core metrics analysis on your data to get alpha/beta diversity?
core_metrics: "no" ## options: yes and no
## -------------------

## --NEEDED FILE PATHS--
## include if raw_sequences = "yes"
raw_seq_dir: "the subdirectory(s) that your raw 16S fasta files live in" ## this should be under whatever you put as the dataset directory above
## assumes that everything after the prefix of your barcodes file is "_barcodes.txt" and your qiime sequence objected is _paired_end_seqs.qza
raw_seqs: "a list of file and/or directory names/prefixes of your raw sequences (if you have more than one) - these are wildcards"
"ex: ["seq1_run/seq1", "seq2_run/seq2", "seq3_run/seq3"]"
## where do you want to trim and truncate your sequences during DADA2?
## pro tip: make sure these values are the same for every set sequencing experiments that you want to compare!
dada2_trim_left_for: 0
dada2_trim_left_rev: 0
dada2_trunc_len_for: 0
dada2_trunc_len_rev: 0

## include if tax_class = "yes"
## if you ran raw sequences, you don't need to provide file paths for your biom_table and rep_seqs
## if not, you need to tell snakemake the file path to your biom_table and rep_seqs
biom_table: NA
rep_seqs: NA
metadata: "what is your QIIME2-approved metadata file called?"

## include if core_metrics = "yes"
## what sampling depth do you want to use for your core metrics analysis? 
## if you're not sure, I'd consult data/qiime/taxonomy_filtered.qzv
core_metrics_sampling_depth: 0
## -------------------
```
Once you have your config file set up the way you want it, you only have one more major thing to set up before you can run my workflow. 


### **Running the actual workflow (finally!!)**

So, after all of your hard work, it's time to attempt to run my workflow. Be warned, you may have to do some debugging but once you get it working, it runs beautifully (much like GitHub). 

I've also included a handy `bash` script under `workflow/` named `run_snakemake.sh`. This basically allows you to freely edit the snakemake command, which could mean switching out your config file, altering the amount of cores on your computer snakemake uses, and adding flags for the workflow as you see fit. So, let's take a look at `run_snakemake.sh`. 

```bash
snakemake \
    -s workflow/snakefile \ ## points to where the snakefile is 
    -c 7 \ ## the amount of cores snakemake will use
    --use-conda \ ## tells snakemake to use your conda environments 
    --keep-going \ ## tells snakemake to keep going if rules fail
    --configfile workflow/config_files/config.yml ## points to where your config file is
    
## if you would like to dry run your workflow, add --dry-run to the above command
```
Once you're satisified with your snakemake command in `run_snakemake.sh`, activate your `snakemake_env` conda environment. From there you can run:

```bash
sh workflow/run_snakemake.sh
```

Happy analyzing! :) 




