#Script to force single core convertion off all images into RGB tifs (somethime AperiCloud fails on machines with many cores, trying to convert too many images at the same time)
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no

nbIm=0
mkdir Tmp-MM-Dir
rm DevAll.sh

#Count the files
for file in $(find ./ -maxdepth 1 -regex ".*\(JPG\|jpg\|png\|PNG\|ARW\|NEF\|CR2\|RW2\|IIQ\)");
do
	nbIm=$(expr $nbIm + 1) 
    f=$(basename "$file")
	echo "Found image : " $f
done  
echo "Found " $nbIm " images."

imNb=0
for file in $(find ./ -maxdepth 1 -regex ".*\(JPG\|jpg\|png\|PNG\|ARW\|NEF\|CR2\|RW2\|IIQ\)");
do
	imNb=$(expr $imNb + 1) 
    f=$(basename "$file")
	echo "echo \"Image \""$imNb"/"$nbIm" : " $f>> DevAll.sh
	echo "mm3d Devlop \"./$f\" 8B=1 Gray=1 NameOut=./Tmp-MM-Dir/"$f"_Ch1.tif" >> DevAll.sh
	echo "mm3d Devlop \"./$f\" 8B=1 Gray=0 NameOut=./Tmp-MM-Dir/"$f"_Ch3.tif" >> DevAll.sh
done  

bash DevAll.sh
