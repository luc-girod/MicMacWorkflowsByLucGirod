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
orthob=0 #boolean for creation of orthophotomosaic
EPSG=32632 # Coordinate system EPSG code, !!!!!!!! be coherent with the WGS84toUTM.xml file !!!!!!
ResolOrtho=1
DoOrtho=0
DEMInit="None"
NamePrefix="SatPleiades"

echo "
	********************************************
	***        MicMac workflow for           ***
	***   Pleiades satellites images         ***
	***         without GCPs                 ***
	********************************************
	"

#input arguments
while getopts "e:f:p:q:d:c:r:smz:g:o:a:i:n:h" opt; do
  case $opt in
    h)
      echo " "
      echo "Usage: $0 -e TIF -f XML -p IMG -q RPC -d 0 -c WGS84toUTM.xml -r 10000 -s -m -z 2 -g 1 -o -a 32632"
      echo "	-e EXTIM   	  : image file extension (JPG, jpg, TIF, tif, png..., default=$EXTIM)."
      echo "	-f EXTRPC     : RPC file extension (XML, xml, ..., default=$EXTRPC)."
      echo "	-p PREFIM	  : Prefix for image name (default=$PREFIM)"
      echo "	-q PREFRPC	  : Prefix for RPC name (default=$PREFRPC)"
      echo "	-d DEG		  : Degree of the polynomial (default=$DEG)"
      echo "	-c CHSYSXML	  : File containing the transform CRS from wgs84 to utm (default=$CHSYSXML)"
      echo "	-r RESSIZE	  : Resolution of the subsampled image for tapioca, (default=$RESSIZE, for full image use -1)"
      echo "	-s 	          : Use 'Schnaps' optimized homologous points (default=$use_Schnaps)"
      echo "	-m 		      : Pause for Mask before correlation (default=$wait_for_mask)"
      echo "	-z ZOOM       : Zoom Level (default=$ZOOM)"
      echo "	-g GRESOL     : Output Ground resolution (in meters)(if not set, will be defined automatically)"
      echo "	-o		      : 0 - no Ortho, 1 - Ortho using all provided images, 2 - Use _P for geometry and _MS for Ortho (default=$orthob)"
      echo "	-a EPSG	  	  : Coordinate system EPSG code (default=$EPSG)"
      echo "	-i DEMInit    : Name of initialization DEM (without suffix, must have a MicMac style XML descriptor as well)"
      echo "	-n NamePrefix : Prefix name for output (default=SatPleiades)"
      echo "	-h	 	      : displays this message and exits."
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
	i)
      DEMInit=$OPTARG
      ;;
	o)
      orthob=$OPTARG
      if [ "$orthob" = 1 ]; then
        ImOrtho="$PREFIM(.*).$EXTIM"
        ImMNT="$PREFIM(.*).$EXTIM"
        ResolOrtho=1
        DoOrtho=1
      elif [ "$orthob" = 2 ]; then
        ImOrtho="$PREFIM(.*_MS.*).$EXTIM"
        ImMNT="$PREFIM(.*_P.*).$EXTIM"
        ResolOrtho=0.5
        DoOrtho=1
      fi
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
	- Image file extension        : $EXTIM
	- RPC file extension          : $EXTRPC
	- Prefix of image file name   : $PREFIM
	- Prefix of RPC file name     : $PREFRPC
	- Degree of polynomial        : $DEG
	- CRS transformation file     : $CHSYSXML
	- Tapioca resolution          : $RESSIZE
	- Use Schnaps                 : $use_Schnaps
	- Pause for mask              : $wait_for_mask
	- ZoomF                       : $ZOOM
	- Output GSD                  : $GRESOL
	- Orthophotomosaic type       : $orthob
	- EPSG code                   : $EPSG
	- Ininialization DEM          : $DEMInit
	- Prefix name for output      : $NamePrefix
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
		For help use : ./SatPleiades.sh -h \n" >&1
	    exit 1 ;;
        * ) echo "
		Only 0 or 1 are valid choices
		For help use : ./SatPleiades.sh -h \n" >&1
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
if [ "$orthob" = 0 ]; then
ImOrtho="$PREFIM(.*).$EXTIM"
ImMNT="$PREFIM(.*).$EXTIM"
fi
#Check WGS84toUTM.xml exist
# TO BE DONE

#convert RPC info from nominal to MicMac format
#(specify the degree of your polynomial + working coordinate system)
mm3d Convert2GenBundle "$PREFIM(.*).$EXTIM" "$PREFRPC\$1.$EXTRPC" RPC-d$DEG Degre=$DEG ChSys=$CHSYSXML
MaltOri=RPC-d$DEG

if [ "$DEG" != 0 ]; then
    #Find Tie points using all images
    mm3d Tapioca All "$PREFIM(.*).$EXTIM" $RESSIZE

    if [ "$use_Schnaps" = true ]; then
        #filter TiePoints (better distribution, avoid clogging)
        mm3d Schnaps .*$EXTIM MoveBadImgs=1
    fi

    #Bundle adjustment, compensation
    mm3d Campari "$PREFIM(.*).$EXTIM" RPC-d$DEG RPC-d$DEG-adj SH=$SH
    MaltOri=RPC-d$DEG-adj
fi

#HERE, MASKING COULD BE DONE!!!
if [ "$wait_for_mask" = true ]; then
    mm3d Tarama $ImMNT $MaltOri
	read -rsp $'Do the masking and Press any key to continue...\n' -n1 key
fi

#Correlation into DEM
if [ "$DEMInit" != "None" ]; then
    if [ "$gresol_set" = true ]; then
        mm3d Malt Ortho "$PREFIM(.*).$EXTIM" $MaltOri EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1 ImOrtho=$ImOrtho ImMNT=$ImMNT DoOrtho=$DoOrtho ResolOrtho=$ResolOrtho DEMInitIMG=$DEMInit.tif DEMInitXML=$DEMInit.xml ZoomI=8 ResolTerrain=$GRESOL
        gdal_calc.py -A MEC-Malt/Correl_STD-MALT_Num_5.tif --outfile=MEC-Malt/AutoMask_STD-MALT_Num_5.tif --calc="A>100"
    else
        mm3d Malt Ortho "$PREFIM(.*).$EXTIM" $MaltOri EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1 ImOrtho=$ImOrtho ImMNT=$ImMNT DoOrtho=$DoOrtho ResolOrtho=$ResolOrtho DEMInitIMG=$DEMInit.tif DEMInitXML=$DEMInit.xml ZoomI=8
        gdal_calc.py -A MEC-Malt/Correl_STD-MALT_Num_5.tif --outfile=MEC-Malt/AutoMask_STD-MALT_Num_5.tif --calc="A>100"
    fi
else
    if [ "$gresol_set" = true ]; then
        mm3d Malt Ortho "$PREFIM(.*).$EXTIM" $MaltOri EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1 ImOrtho=$ImOrtho ImMNT=$ImMNT DoOrtho=$DoOrtho ResolOrtho=$ResolOrtho ResolTerrain=$GRESOL
    else
        mm3d Malt Ortho "$PREFIM(.*).$EXTIM" $MaltOri EZA=1 ZoomF=$ZOOM VSND=-9999 DefCor=0 Spatial=1 MaxFlow=1 ImOrtho=$ImOrtho ImMNT=$ImMNT DoOrtho=$DoOrtho ResolOrtho=$ResolOrtho
    fi
fi

#Merge orthophotos to create Orthomosaic
if [ $DoOrtho -eq 1 ]; then
        mm3d Tawny Ortho-MEC-Malt RadiomEgal=0
fi

#Post Processing ######################################
echo "
	********************************************
	***        Post-processing               ***
	********************************************
	"

mkdir OUTPUT

cd MEC-Malt
	lastDEM=($(find . -regex '.*Z_Num[0-9]*_DeZoom[0-9]*_STD-MALT.tif' | sort -r))
	lastNuageImProf=($(find . -regex '.*NuageImProf.*[0-9].xml' | sort -r))
	lastmsk=($(find . -regex '.*AutoMask_STD-MALT_Num_[0-9]*\.tif' | sort -r))
	lastcor=($(find . -regex '.*Correl_STD-MALT_Num_[0-9]*\.tif' | sort -r))
	lastDEMstr="${lastDEM%.*}"
	lastcorstr="${lastcor%.*}"
	lastmskstr="${lastmsk%.*}"
	cp $lastDEMstr.tfw $lastcorstr.tfw
	cp $lastDEMstr.tfw $lastmskstr.tfw
	# Converting MicMac output DEM to files with masked areas as nodata
	echo "gdal_translate -a_srs EPSG:"$EPSG" $lastDEM tmp_geo.tif"
	gdal_translate -a_srs EPSG:$EPSG $lastDEM tmp_geo.tif
	echo "gdal_translate -a_srs EPSG:"$EPSG" -a_nodata 0 $lastmsk tmp_msk.tif"
	gdal_translate -a_srs EPSG:$EPSG -a_nodata 0 $lastmsk tmp_msk.tif
	echo "gdal_calc.py -A tmp_msk.tif -B tmp_geo.tif --outfile=../OUTPUT/"${NamePrefix}"_DEM_MICMAC_"$EPSG".tif --calc=\"B*(A>0)\" --NoDataValue=-9999"
	gdal_calc.py -A tmp_msk.tif -B tmp_geo.tif --outfile=../OUTPUT/${NamePrefix}_DEM_MICMAC_$EPSG.tif --calc="B*(A>0)" --NoDataValue=-9999
	rm tmp_geo.tif tmp_msk.tif
cd ..

gdal_translate -a_srs EPSG:$EPSG MEC-Malt/$lastcor OUTPUT/${NamePrefix}_CORR_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE

# export Ortho
if [ $DoOrtho -eq 1 ]; then
	if [ -f "./Ortho-MEC-Malt/Orthophotomosaic_Tile_0_0.tif" ]
	then
        cd Ortho-MEC-Malt
		mosaic_micmac_tiles.py -filename Orthophotomosaic
        cd ..
	fi
	gdal_translate -a_nodata 0 -a_srs EPSG:$EPSG Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/${NamePrefix}_ORTHOMOSAIC_MICMAC_$EPSG.tif -co COMPRESS=DEFLATE
fi

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
