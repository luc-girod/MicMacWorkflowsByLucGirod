#This file is a workflow for modeling a statue, with images taken from around it.

#I would like to remind users that an angle of 10° between view angle is optimal.


# add default values
EXTENSION=JPG
use_Schnaps=true
ZOOM=2

while getopts "e:sz:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: DroneNadir.sh -e JPG -x 55000 -y 6600000 -u \"32 +north\" -p true -r 0.05"
      echo "	-e EXTENSION   : image file type ($EXTENSION, $EXTENSION, TIF, png..., default=$EXTENSION)."
      echo "	-s SH          : Do not use 'Schnaps' optimised homologous points."
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
    \?)
      echo "DroneNadir.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "DroneNadir.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

if [ "$use_schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi

#Find Tie points using multi-resolution
mm3d Tapioca MulScale .*$EXTENSION 500 2000

if [ "$use_schnaps" = true ]; then
	#filter TiePoints (better distribution, avoid clogging)
	mm3d Schnaps .*$EXTENSION
fi
#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=$SH
#Visualize relative orientation
mm3d AperiCloud .*$EXTENSION Ori-Arbitrary

#HERE, MASKING COULD BE DONE!!!

#Do the correlation of the images
mm3d C3DC Statue .*$EXTENSION Ori-Arbitrary ZoomF=$ZOOM 
