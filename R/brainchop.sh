#!/bin/bash
#SBATCH --job-name=BRAINCHOP
#SBATCH --partition=gpu          # <-- only GPU workloads belong here
#SBATCH --gres=gpu:1             # 1 GPU; change to :2, :4 … if the code scales
#SBATCH --cpus-per-task=4        # threads available to PyTorch / nnUNet
#SBATCH --mem=20G
#SBATCH --time=1-00:00:00
#SBATCH --output=eofiles/BRAINCHOP_%A.out
#SBATCH --error=eofiles/BRAINCHOP_%A.err

## INSTALL THE CONDAENV
# module unload conda_R || true
# module unload freesurfer || true
# module unload fsl || true
# module load conda
# conda create -n brainchop_env python=3.11
# conda activate brainchop
# uv pip install brainchop

source ~/.bash_profile
module unload conda_R || true
module unload freesurfer || true
module unload fsl || true
module load conda
conda activate brainchop_env
cd $cq500

size=256
files=`ls data/noneck_${size}/*.nii.gz`
ifile=${files}
brain_outdir="data/noneck_brain_extracted_brainchop_${size}"
mkdir -p ${brain_outdir}
mask_outdir="data/noneck_brain_mask_brainchop_${size}"
mkdir -p ${mask_outdir}


# export CUDA_DIRECT_HOST_MEM=0
for ifile in $files;
do
  echo "$ifile"
  bn=`basename ${ifile}`
  brain="${brain_outdir}/${bn}"
  mask="${mask_outdir}/${bn}"
  if [ ! -f "${brain}"  ] || [ ! -f "${mask}"  ]; then
    echo "processing ${ifile}"
    if [ -z "$CUDA_VISIBLE_DEVICES" ];
    then
      echo "using LLVM"
      LLVM=1 brainchop ${ifile} --output ${brain} --mask ${mask} --ct --model mindgrab
    else
      echo "using GPU"
      GPU=1 brainchop ${ifile} --output ${brain} --mask ${mask} --ct --model mindgrab
    fi
  fi
done

