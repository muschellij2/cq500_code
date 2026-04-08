#!/bin/bash
#SBATCH --job-name=CPUCTBET
#SBATCH --time=7-00:00:00
#SBATCH --output=eofiles/CPUCTBET_%A.out
#SBATCH --error=eofiles/CPUCTBET_%A.err

source ~/.bash_profile
module unload conda_R
module load conda
conda activate ctbet_env
cd $cq500
cd CT_BET
python unet_CT_SS.py
