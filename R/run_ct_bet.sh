#!/bin/bash
#SBATCH --job-name=CTBET
#SBATCH --partition=gpu          # <-- only GPU workloads belong here
#SBATCH --gres=gpu:1             # 1 GPU; change to :2, :4 … if the code scales
#SBATCH --cpus-per-task=4        # threads available to PyTorch / nnUNet
#SBATCH --mem=32G
#SBATCH --time=2-00:00:00
#SBATCH --output=eofiles/CTBET_%A.out
#SBATCH --error=eofiles/CTBET_%A.err

source ~/.bash_profile
module unload conda_R
module load conda
conda activate ctbet_env
cd $cq500
cd CT_BET
export LD_LIBRARY_PATH=/jhpce/shared/jhpce/core/JHPCE_tools/3.0/lib:/usr/local/lib/python3.9/site-packages/nvidia/cudnn/lib:/jhpce/shared/jhpce/core/conda/miniconda3-23.3.1/envs/cudatoolkit-11.8.0/lib:$LD_LIBRARY_PATH
python unet_CT_SS.py
