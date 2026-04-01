aria2c -x5 -i cq500_files.txt 

zip -FF CQ500-CT-120.zip --out CQ500-CT-120.zip
rm -f "data/dicom/CQ500CT120 CQ500CT120/Unknown Study/CT Thin Plain/CT000168.dcm"
