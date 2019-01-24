# MicMac workflow for modeling a statue, with images taken from around it, not necessarily in an orderly manner.
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no


#I would like to remind users that an angle of 10° between view angle is optimal.


# add default values
EXTENSION=JPG
use_Schnaps=true
use_Circ=false
use_mask=false
ZOOM=2

while getopts "e:sl:c:mz:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for 3D acquisition going around a subject (statue, with -c option), or more random."
      echo "usage: Statue.sh -e JPG -m"
      echo "	-e EXTENSION   : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-s             : Do not use 'Schnaps' optimised homologous points (does by default)."
      echo "	-l             : Use 'Tapioca Line N' (if images are taken in a line with N the number of image before and after considered in match,\n def false -> Tapioca Mulscale)."
      echo "	-c             : Use 'Tapioca Line Circ=1 N '(if images are taken in a circle with N the number of image before and after considered in match,\n (if last image is linked with first), def false -> Tapioca Mulscale)."
      echo "	-m             : Use 3D Mask for correlation (does not by default, tries whole visible objects)."
      echo "	-z ZOOM        : Zoom Level (default=2)"
      echo "	-h	  : displays this message and exits."
      echo " "
      exit 0
      ;;   
	e)
      EXTENSION=$OPTARG
      ;;
	z)
      ZOOM=$OPTARG
      ;;
	s)
      use_Schnaps=false
      ;; 
	c)
      use_Circ=true
	  circVal=$OPTARG
      ;; 
	l)
      use_Line=true
	  lineVal=$OPTARG
      ;; 
	m)
      use_mask=true
      ;;  
    \?)
      echo "Statue.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "Statue.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

if [ "$use_Schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi

#Convert all images to tif (BW and RGB) for use in AperiCloud (because it otherwise breaks if too many CPUs are used)
DevAllPrep.sh


#Find Tie points using multi-resolution
if [ "$use_Circ" = true ]; then
	echo "Using Tapioca Circ .*$EXTENSION 2000 $circVal Circ=1"
	mm3d Tapioca Line .*$EXTENSION 2000 $circVal Circ=1
elif [ "$use_Line" = true ]; then
	echo "Using mm3d Tapioca Line .*$EXTENSION 2000 $lineVal"
	mm3d Tapioca Line .*$EXTENSION 2000 $lineVal
else
	echo "Using Tapioca MulScale .*$EXTENSION 500 2000"
	mm3d Tapioca MulScale .*$EXTENSION 500 2000
fi



if [ "$use_Schnaps" = true ]; then
	#filter TiePoints (better distribution, avoid clogging)
	mm3d Schnaps .*$EXTENSION MoveBadImgs=1
fi
#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=$SH
#Visualize relative orientation
mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=$SH

#HERE, MASKING COULD BE DONE!!!
if [ "$use_mask" = true ]; then
	read -rsp $'Create a 3D mask on the Apericloud using (from another terminal): \n mm3d SaisieMasqQT AperiCloud_Arbitrary.ply \n Then press any key to continue...\n' -n1 key
	#Do the correlation of the images
	if [ "$use_Schnaps" = true ]; then
		mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM Masq3D=AperiCloud_Arbitrary__mini.ply SH=$SH
	else
		mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM Masq3D=AperiCloud_Arbitrary.ply SH=$SH
	fi
else
	#Do the correlation of the images with no mask
	mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM SH=$SH
fi


