#!/bin/bash
#SBATCH --job-name=CBRAINCHOP
#SBATCH --partition=gpu          # <-- only GPU workloads belong here
#SBATCH --gres=gpu:1             # 1 GPU; change to :2, :4 … if the code scales
#SBATCH --cpus-per-task=4        # threads available to PyTorch / nnUNet
#SBATCH --mem=20G
#SBATCH --time=1-00:00:00
#SBATCH --output=eofiles/CBRAINCHOP_%A.out
#SBATCH --error=eofiles/CBRAINCHOP_%A.err

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
module load freesurfer || true
module unload fsl || true
module load conda
conda activate brainchop_env
cd $cq500

files=`ls data/noneck_512/*.nii.gz`
ifile=${files}
brain_outdir="data/noneck_brain_extracted_brainchop_conform"
mkdir -p ${brain_outdir}
mask_outdir="data/noneck_brain_mask_brainchop_conform"
mkdir -p ${mask_outdir}


# export CUDA_DIRECT_HOST_MEM=0
for infile in $files;
do
  echo "$infile"
  bn=`basename ${infile}`
  brain="${brain_outdir}/${bn}"
  mask="${mask_outdir}/${bn}"
  if [ ! -f "${brain}"  ] || [ ! -f "${mask}"  ]; then
    echo "processing ${infile}"
    ifile=`mktemp --suffix=".nii.gz"`
    # conform to 256x256x256
    mri_convert ${infile} ${ifile} --conform
    echo "conformed ${ifile}"
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

