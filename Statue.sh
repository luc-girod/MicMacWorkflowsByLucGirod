# MicMac workflow for modeling a statue, with images taken from around it, not necessarily in an orderly manner.
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no


#I would like to remind users that an angle of 10° between view angle is optimal.


# add default values
EXTENSION=JPG
use_Schnaps=true
use_Circ=false
wait_for_mask=false
ZOOM=2

while getopts "e:scmz:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: Statue.sh -e JPG -m"
      echo "	-e EXTENSION   : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-s             : Do not use 'Schnaps' optimised homologous points (does by default)."
      echo "	-c             : Use Tapioca Line Circ=1 (if images are taken in a circle, def false -> Tapioca Mulscale)."
      echo "	-m             : Pause for Mask before correlation (does not by default)."
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
	s)
      use_Circ=true
      ;; 
	m)
      wait_for_mask=true
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
	echo "Using Tapioca Circ .* 2000 8"
	mm3d Tapioca Circ .*$EXTENSION 2000 8
else
	echo "Using Tapioca MulScale .* 500 2000"
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
if [ "$wait_for_mask" = true ]; then
	read -rsp $'Press any key to continue...\n' -n1 key
fi
	
#Do the correlation of the images
if [ "$use_Schnaps" = true ]; then
	mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM Masq3D=AperiCloud_Arbitrary__mini.ply
else
	mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM Masq3D=AperiCloud_Arbitrary.ply
fi

