#Script to force single core convertion off all images into RGB tifs (somethime AperiCloud fails on machines with many cores, trying to convert too many images at the same time)
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no

nbIm=0
mkdir Tmp-MM-Dir
rm DevAll.sh
for file in $(find ./ -maxdepth 1 -regex ".*\(JPG\|jpg\|png\|PNG\|ARW\|NEF\|CR2\|RW2\|IIQ\)");
do
	nbIm=$(expr $nbIm + 1) 
    f=$(basename "$file")
    #echo "mm3d MpDcraw \"./$f\"  Add16B8B=0  ConsCol=0  ExtensionAbs=None  16B=0  CB=1  NameOut=./Tmp-MM-Dir/"$f"_Ch3.tif Gamma=2.2 EpsLog=1.0" >> DevAll.sh
	echo "mm3d Devlop \"./$f\" 8B=1 Gray=1 NameOut=./Tmp-MM-Dir/"$f"_Ch1.tif" >> DevAll.sh
	echo "mm3d Devlop \"./$f\" 8B=1 Gray=0 NameOut=./Tmp-MM-Dir/"$f"_Ch3.tif" >> DevAll.sh
	echo "Found image : " $f
done  
echo "Found " $nbIm " images."
bash DevAll.sh
