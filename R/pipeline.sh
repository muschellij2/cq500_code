

Rnosave R/01_create_dicom_filenames.R -J FILES -o %x_%A.out -e %x_%A.err
Rnosave R/01.1_dump_header.R -J PLOT --mem=10G -o %x_%A.out -e %x_%A.err
Rnosave R/01.2_join_headers.R -J JOIN --mem=20G -o %x_%A.out -e %x_%A.err --dependency=afterok:30156577



Rnosave R/02_convert_dicom_to_nifti.R -J CONVERT --array=6-491 --mem=10G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err
Rnosave R/02.1_get_image_dimensions.R -J DIMS --mem=8G -o %x_%A.out -e %x_%A.err

# Rnosave R/03_plot_nifti.R -J PLOT --array=1480-5109 --mem=8G -o %x_%A_%a.out -e %x_%A_%a.err
Rnosave R/03_interpolate_512_and_256.R -J RESAMPLE --array=1-1274 --mem=20G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err


Rnosave R/04_remove_neck.R -J NONECK --array=6-1274 --mem=20G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err


Rnosave R/04_skull_strip.R -J SS --array=6-1274 --mem=20G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err

Rnosave R/04_skull_strip.R -J SS --array=217,706,762 --mem=40G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err

Rnosave R/05_plot_nifti.R -J PLOT  --array=6-1274 --mem=20G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err

Rnosave R/06_plot_strip.R -J SPLOT  --array=1-1274 --mem=20G -o eofiles/%x_%A_%a.out -e eofiles/%x_%A_%a.err


sbatch R/hd_ct_bet.sh
# sbatch R/run_ct_bet.sh
sbatch R/run_ct_bet_cpu.sh

sbatch R/brainchop.sh

sbatch R/dockerctbet.sh


Rnosave R/manual_04_skull_strip.R -J SS --mem=10G -o %x_%A.out -e %x_%A.err

