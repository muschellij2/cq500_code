#!/bin/bash
#SBATCH --job-name=DOCKERBET
#SBATCH --partition=gpu          # <-- only GPU workloads belong here
#SBATCH --gres=gpu:1             # 1 GPU; change to :2, :4 … if the code scales
#SBATCH --cpus-per-task=4        # threads available to PyTorch / nnUNet
#SBATCH --mem=12G
#SBATCH --time=1-00:00:00
#SBATCH --output=eofiles/DOCKERBET_%A.out
#SBATCH --error=eofiles/DOCKERBET_%A.err

source ~/.bash_profile
module unload conda_R
module load conda


outdir="$cq500/data/noneck_brain_mask_dockerctbet_512"
mkdir -p ${outdir}

# Prepare folders for NNUNETV2
cd $cq500/CTbet-Docker
conda activate dockerctbet
# mkdir -p output

export nnUNet_results=./assets
export nnUNet_raw=./assets
export nnUNet_preprocessed=./assets

nnUNetv2_install_pretrained_model_from_zip ./assets/nnUNetv2_pretrained_model.zip

for file in ./input/*; do
    if [ "${file##*_}" != "0000.nii.gz" ]; then
        mv "$file" "${file%.nii.gz}_0000.nii.gz"
    fi
done

nnUNetv2_predict -i ./input -o ${outdir} -d 033 -c 2d -f all -device cuda

