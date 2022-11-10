# Script to gather all images and RPC files from a SPOT6/7 or PHR1A/B folder into a processing folder
# Needs to be ran in a subfolder of the delivery folder
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no

for file in $(find .. -name "RPC*");
do
	cp $file $(basename "$file")
	echo "Found RPC file : " $(basename "$file")
done

for file in $(find .. -name "*.TIF");
do
	cp $file $(basename "$file")
	echo "Found Image file : " $(basename "$file")
done  
rename _R1C1 "" *_R1C1.TIF
