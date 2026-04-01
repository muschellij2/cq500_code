#!/bin/bash
#SBATCH --job-name=hdctbet_gpu
#SBATCH --partition=gpu          # <-- only GPU workloads belong here
#SBATCH --gres=gpu:1             # 1 GPU; change to :2, :4 … if the code scales
#SBATCH --cpus-per-task=4        # threads available to PyTorch / nnUNet
#SBATCH --mem=12G
#SBATCH --time=4-00:00:00
#SBATCH --output=eofiles/HDCTBET_%A.out
#SBATCH --error=eofiles/HDCTBET_%A.err

source ~/.bash_profile
cd $cq500


files=`ls data/noneck_512/*.nii.gz`
outdir="data/noneck_brain_extracted_hdctbet_512"
mkdir -p ${outdir}

if [ -n "$CUDA_VISIBLE_DEVICES" ]; then
    GPU_ID=${CUDA_VISIBLE_DEVICES%%,*}
    EXTRA_ARGS="-device $GPU_ID"
else
    EXTRA_ARGS=""
fi

echo "EXTRA_ARGS are ${EXTRA_ARGS}"

conda activate hd_ctbet
for ifile in $files;
do
  bn=`basename ${ifile}`
  ./HD-CTBET/HD_CTBET/hd-ctbet -i ${ifile} -o "${outdir}/${bn}" ${EXTRA_ARGS}
done
