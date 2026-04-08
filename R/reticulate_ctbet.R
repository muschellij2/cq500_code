library(reticulate)
setwd(here::here("CT_BET"))
reticulate::use_condaenv("ctbet_env")
modelct = reticulate::import_from_path("model_CT_SS", path = "CT_BET")
genUnet = modelct$Unet_CT_SS
code_dir = "."


pred_folder= ''
train=FALSE
predict=TRUE # run predictions for a specific weights.

datagen=''
datagenPrams=''
afold=''
#===================set optimizer=====================#
lr=1e-5
decay=1e-6
optimizer = 'adam'
#optimizer = SGD(lr=1e-4, momentum=0.9, decay=1e-9, nesterov=True)
#========================================================#

image_folder = basename(tempfile())
full_image_folder = file.path(code_dir, image_folder)
dir.create(full_image_folder, recursive = TRUE, showWarnings = FALSE)
file.copy(here::here("data/noneck_512/CQ500CT0_CT-4cc-sec-150cc-D3D-on-2.nii.gz"), full_image_folder)
save_folder = basename(tempfile())
full_save_folder = file.path(code_dir, save_folder)
dir.create(full_save_folder, recursive = TRUE, showWarnings = FALSE)
oLabel = "blah"

unetSS = genUnet(
  root_folder = code_dir, 
  image_folder = image_folder,
  mask_folder = 'mask_data',
  save_folder= save_folder,
  pred_folder = pred_folder,
  savePredMask=TRUE,
  testLabelFlag=FALSE,
  testMetricFlag=FALSE, 
  dataAugmentation = FALSE,
  logFileName= 'log.txt',
  datagen=datagen,
  oLabel=oLabel,
  checkWeightFileName=paste0(oLabel, '.h5'),
  afold=afold, 
  numEpochs=100L,
  bs = 1L, 
  nb_classes=2L,
  sC=2L, #saved class
  img_row=512L,
  img_col=512L,
  channel=1L,
  classifier = 'softmax',
  optimizer =optimizer,
  lr=lr,
  decay=decay,
  dtype='float32',
  dtypeL='uint8',
  wType='slice',
  loss='categorical_crossentropy',
  metric='accuracy',
  model='unet')

unetSS$weight_folder=file.path(code_dir,'weights_folder')
weightFile=file.path(unetSS$weight_folder,'unet_CT_SS_20171114_170726.h5')
unetSS$Predict(weightFile)

unlink(full_image_folder, recursive = TRUE)
# unlink(full_save_folder, recursive = TRUE)
#to run unet3D model, use Predict3D
