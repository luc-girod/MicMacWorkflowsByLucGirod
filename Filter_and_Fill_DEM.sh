#Workflow to filter and fill a DEM produced by MicMac
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no


# example:
# ./Filter_and_Fill_DEM.sh DEM.tif CORRELATION.tif



# add default values
Z_MIN=-1000;
Z_MAX=9000;

while getopts "d:c:b:t:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: Filter_and_Fill_DEM.sh DEM.tif CORRELATION.tif -b -1000 -t 9000"
      echo "	-d DEM_IN        : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-c CORR          : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-b Z_MIN         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-t Z_MAX         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0
      ;; 
    d)
      DEM_IN=$OPTARG
	  DEM_Name="${DEM_IN%.*}"
      ;;      	
    c)
      CORR=$OPTARG
	  CORR_Name="${CORR%.*}"
      ;;    	
    b)
      Z_MIN=$OPTARG
      ;; 
    t)
      Z_MAX=$OPTARG
      ;; 
    \?)
      echo "Filter_and_Fill_DEM.sh: Invalid option: -$OPTARG" >&1
      exit 1
      ;;
    :)
      echo "Filter_and_Fill_DEM.sh: Option -$OPTARG requires an argument." >&1
      exit 1
      ;;
  esac
done

echo "Filter_and_Fill_DEM with:"
echo " DEM        : "$DEM_IN
echo " DEM_Name   : "$DEM_Name
echo " CORR       : "$CORR
echo " CORR_Name  : "$CORR_Name
echo " Z_MIN      : "$Z_MIN
echo " Z_MAX      : "$Z_MAX




# First filter by correlation score and height thresholds
echo "gdal_calc.py  -A $DEM_IN -B $CORR --calc=\"(B>200)*(A>$Z_MIN)*(A<$Z_MAX)\" --outfile=\"$CORR_Name\"_Thresh.tif --NoDataValue=0 --type=Byte"
#gdal_calc.py -A "$DEM_IN" -B "$CORR" --calc="(B>180)" --outfile="$CORR_Name"_Thresh.tif --NoDataValue=0 --type=Byte
gdal_calc.py -A "$DEM_IN" -B "$CORR" --calc="((B>200)*(A>$Z_MIN)*(A<$Z_MAX))" --outfile="$CORR_Name"_Thresh.tif --NoDataValue=0 --type=Byte

echo "convert $CORR_Name""_Thresh.tif -morphology Open Octagon:15 $CORR_Name""_Open.tif"
convert "$CORR_Name"_Thresh.tif -morphology Open Octagon:15 "$CORR_Name"_Open.tif
listgeo "$CORR" > "$CORR_Name"GEOTIFF_Data
geotifcp -g "$CORR_Name"GEOTIFF_Data "$CORR_Name"_Open.tif "$CORR_Name"_Open_Geotiff.tif
#gdal_translate -a_nodata 0 "$CORR_Name"_Open_Geotiff.tif "$DEM_Name"_Mask.tif

rm "$CORR_Name"_Thresh.tif "$CORR_Name"_Open.tif "$CORR_Name"_Open_Geotiff.tif

gdal_calc.py -A "$DEM_IN" -B "$DEM_Name"_Mask.tif --calc="(A*B)" --outfile="$DEM_Name"_Masked.tif --NoDataValue=0 --type=float

gdal_fillnodata.py -md 100 -si 2 "$DEM_Name"_Masked.tif -nomask "$DEM_Name"_Filled.tif

