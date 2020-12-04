#!/bin/bash

#Workflow MICMAC for Pleiades sat images
#
# Modified from Luc Girod https://github.com/luc-girod/MicMacWorkflowsByLucGirod/blob/master/DroneNadir.sh
# 	Jules Fleury, SIGEO/CEREGE
#	08/2018

# add default values
EXTIM=TIF # Image file extension
EXTRPC=XML # RPC file extension
PREFIM=IMG # Prefix for image name
PREFRPC=RPC # Prefix for RPC name
DEG=0 # Degree of the polynomial
CHSYSXML=WGS84toUTM.xml #File containing the change transform coordinate sys from wgs84 to utm
# necessary to check in this file that the UTM zone is OK
use_Schnaps=false
SH=  #postfix for homologous points in case of schnaps use
wait_for_mask=false
ZOOM=2 # Final zoom
gresol_set=false # ground resolution set
RESSIZE=10000 # RESOLUTION OF SUBSAMPLED IMAGE FOR TAPIOCA, FOR FULL IMAGE USE -1
orthob=false #boolean for creation of orthophotomosaic
EPSG=32632 # Coordinate system EPSG code, !!!!!!!! be coherent with the WGS84toUTM.xml file !!!!!!

echo "
	********************************************
	***        MicMac workflow for           ***
	***   Pleiades satellites images         ***
	***         without GCPs                 ***
	********************************************
	"

#input arguments
while getopts "e:f:p:q:d:c:r:smz:g:oa:h" opt; do
  case $opt in
    h)
      echo " "
      echo "Usage: $0 -e TIF -f XML -p IMG -q RPC -d 0 -c WGS84toUTM.xml -r 10000 -s -m -z 2 -g 1 -o -a 32632"
      echo "	-e EXTIM   	  : image file extension (JPG, jpg, TIF, tif, png..., default=$EXTIM)."
      echo "	-f EXTRPC         : RPC file extension (XML, xml, ..., default=$EXTRPC)."
      echo "	-p PREFIM	  : Prefix for image name (default=$PREFIM)"
      echo "	-q PREFRPC	  : Prefix for RPC name (default=$PREFRPC)"
      echo "	-d DEG		  : Degree of the polynomial (default=$DEG)"
      echo "	-c CHSYSXML	  : File containing the transform CRS from wgs84 to utm (default=$CHSYSXML)"
      echo "	-r RESSIZE	  : Resolution of the subsampled image for tapioca, (default=$RESSIZE, for full image use -1)"
      echo "	-s 	          : Use 'Schnaps' optimized homologous points (default=$use_Schnaps)"
      echo "	-m 		  : Pause for Mask before correlation (default=$wait_for_mask)"
      echo "	-z ZOOM           : Zoom Level (default=$ZOOM)"
      echo "	-g GRESOL         : Output Ground resolution (in meters)(if not set, will be defined automatically)"
      echo "	-o		  : Create Orthophotomosaic alose (default=$orthob)"
      echo "	-a EPSG	  	  : Coordinate system EPSG code (default=$EPSG) "
      echo "	-h	 	  : displays this message and exits."
      echo " "
      exit 0
      ;;
	e)
      EXTIM=$OPTARG
      ;;
	f)
      EXTRPC=$OPTARG
      ;;
	p)
      PREFIM=$OPTARG
      ;;
	q)
      PREFRPC=$OPTARG
      ;;
	d)
      DEG=$OPTARG
      ;;
	c)
      CHSYSXML=$OPTARG
      ;;
	r)
      RESSIZE=$OPTARG
      ;;
	s)
      use_Schnaps=true
      ;;
	m)
      wait_for_mask=true
      ;;
	z)
      ZOOM=$OPTARG
      ;;
	a)
      EPSG=$OPTARG
      ;;
	g)
      gresol_set=true
      GRESOL=$OPTARG
      ;;
	o)
      orthob=true
      ;;
    \?)
      echo "Script : Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "Script.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

#check arguments and choose to continue or not
selection=
until [  "$selection" = "1" ]; do
    echo "
    CHECK (carefully) PARAMETERS
	- Image file extension : $EXTIM
	- RPC file extension : $EXTRPC
	- Prefix of image file name : $PREFIM
	- Prefix of RPC file name : $PREFRPC
	- Degree of polynomial : $DEG
	- CRS transformation file : $CHSYSXML
	- Subsampling resolution for Tapioca : $RESSIZE
	- Use Schnaps for filtering tie points : $use_Schnaps
	- Pause for mask images or create mask for chantier : $wait_for_mask
	- ZoomF : $ZOOM
	- Ground resolution for output : $GRESOL
	- Create an orthophotomosaic : $orthob
	- EPSG code : $EPSG
"
    echo "
    CHOOSE BETWEEN
    1 - Continue with these parameters
    0 - Exit program

    2 - Help
"
    echo -n "Enter selection: "
    read selection
    echo ""
    case $selection in
        1 ) echo "Let's process now" ; continue ;;
        0 ) exit ;;
	2 ) echo "
		For help use : ./SatPleiades.sh -h
	   " >&1
	   exit 1 ;;
        * ) echo "
		Only 0 or 1 are valid choices
		For help use : ./SatPleiades.sh -h
		" >&1
		exit 1 ;;
    esac
done

# MICMAC PROCESSING #################################

if [ "$use_Schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi

#Check WGS84toUTM.xml exist
# TO BE DONE

#convert RPC info from nominal to MicMac format
#(specify the degree of your polynomial + working coordinate system)
mm3d Convert2GenBundle "$PREFIM(.*).$EXTIM" "$PREFRPC\$1.$EXTRPC" RPC-d$DEG Degre=$DEG ChSys=$CHSYSXML

#Find Tie points using all images
mm3d Tapioca All "$PREFIM(.*).$EXTIM" $RESSIZE

if [ "$use_Schnaps" = true ]; then
	#filter TiePoints (better distribution, avoid clogging)
	mm3d Schnaps .*$EXTIM MoveBadImgs=1
fi

#Bundle adjustment, compensation
mm3d Campari "$PREFIM(.*).$EXTIM" RPC-d$DEG RPC-d$DEG-adj SH=$SH

#HERE, MASKING COULD BE DONE!!!
if [ "$wait_for_mask" = true ]; then
	read -rsp $'Do the masking and Press any key to continue...\n' -n1 key
fi

#Correlation into DEM
if [ "$gresol_set" = true ]; then
	mm3d Malt Ortho "$PREFIM(.*).$EXTIM" RPC-d$DEG-adj ResolTerrain=$GRESOL EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1
else
	mm3d Malt Ortho "$PREFIM(.*).$EXTIM" RPC-d$DEG-adj EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1
fi

#Merge orthophotos to create Orthomosaic
if [ "$orthob"=true ]; then
        mm3d Tawny Ortho-MEC-Malt
fi

#Post Processing ######################################
echo "
	********************************************
	***        Post-processing               ***
	********************************************
	"

mkdir OUTPUT
cd MEC-Malt
#get the last file names
finalDEMs=($(ls Z_Num*_DeZoom*_STD-MALT.tif))
finalcors=($(ls Correl_STD-MALT_Num*.tif))
finalautomask=($(ls AutoMask_STD-MALT_Num*.tif))
DEMind=$((${#finalDEMs[@]}-1))
corind=$((${#finalcors[@]}-1))
autoind=$((${#finalautomas[@]}-1))
lastDEM=${finalDEMs[DEMind]}
lastcor=${finalcors[corind]}
lastautomask=${finalautomask[autoind]}
laststr="${lastDEM%.*}"
corrstr="${lastcor%.*}"
automstr="${lastautomask%.*}"
echo "DEM : lastDEM=$lastDEM; laststr=$laststr"
echo "CORRELATION : lastcor=$lastcor; corrstr=$corrstr"
echo "AUTOMASK : lastautomask=$lastautomask; automstr=$automstr"
#copy tfw
cp $laststr.tfw $corrstr.tfw
cp $laststr.tfw $automstr.tfw
cd ..

#export DEM, CORR and AUTOMASK with gdal
gdal_translate -a_srs EPSG:$EPSG MEC-Malt/$lastDEM OUTPUT/DEM_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE
gdal_translate -a_srs EPSG:$EPSG MEC-Malt/$lastcor OUTPUT/CORR_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE
gdal_translate -a_srs EPSG:$EPSG MEC-Malt/$lastautomask OUTPUT/AUTOMASK_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE

# export Ortho
if [ "$orthob"=true ]; then
	if [ -f "./Ortho-MEC-Malt/Orthophotomosaic_Tile_0_0.tif" ]
	then
		echo "
		Cannot export Orthomosaic as tiles must be merged first
		Use for example otbcli_TileFusion
		"
	else
		gdal_translate -a_nodata 0 -a_srs EPSG:$EPSG Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/ORTHOMOSAIC_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE
	fi
fi

# Set no correlation zones to NODATA using AUTOMASK
cd OUTPUT
gdal_calc.py -A DEM_MICMAC_$EPSG.tif -B AUTOMASK_MICMAC_$EPSG.tif --calc=A*B --NoDataValue=0 --outfile=DEM_MICMAC_$EPSG-cleaned.tif
gdal_translate DEM_MICMAC_$EPSG-cleaned.tif DEM_MICMAC_$EPSG-clean.tif -co COMPRESS=DEFLATE
rm DEM_MICMAC_$EPSG-cleaned.tif

#Hillshading
#gdaldem hillshade DEM_MICMAC_$EPSG-clean.tif SHD_DEM_MICMAC_$EPSG-clean.tif -co COMPRESS=DEFLATE

echo "
	********************************************
	***               Finished               ***
	***     Results are in OUTPUT folder     ***
	********************************************
	"

# One should then filter the resulting DEM using either Despeckle or Gaussian filters

# For Orthophoto, automatic processing is not done as usually a tile merging must be done before
