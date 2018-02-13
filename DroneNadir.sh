
# add default values for ZoomF, RESTERR, CorThr, water_mask and NoCorDEM
EXTENSION=$EXTENSION
X_OFF=0;
Y_OFF=0;
utm_set=false
do_ply=true
resol_set=false

while getopts "e:x:y:u:pr:h" opt; do
  case $opt in
    h)
      echo "Run the second step in the MMASTER processing chain."
      echo "usage: WorkflowASTER_GT_Pt2.sh -s SCENENAME -z 'UTMZONE' -f ZOOMF -t RESTERR -w false -h"
      echo "	-e EXTENSION : image file type ($EXTENSION, $EXTENSION, TIF, png..., default=$EXTENSION)."
      echo "	-x X_OFF     : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF     : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE   : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-p do_ply    : export ply file (default=true)."
      echo "	-r RESOL     : Ground resolution (in meters)"
      echo "	-h	  : displays this message and exits."
      echo " "
      exit 0
      ;;   
	e)
      EXTENSION=$OPTARG
      ;;
	u)
      UTM=$OPTARG
      utm_set=true
      ;;  
	u)
      RESOL=$OPTARG
      resol_set=true
      ;;    
	x)
      X_OFF=$OPTARG
      ;;	
	y)
      Y_OFF=$OPTARG
      ;;	
    p)
      do_ply=$OPTARG
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
if [!utm_set]; then
	echo "UTM zone not set"
	exit 1
fi

#create UTM file
echo "<SystemeCoord>                                                                                              " >> SysUTM.xml
echo "         <BSC>                                                                                              " >> SysUTM.xml
echo "            <TypeCoord>  eTC_Proj4 </TypeCoord>                                                             " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysUTM.xml
echo "            <AuxStr>  +proj=utm +zone=" $UTM " +ellps=WGS84 +datum=WGS84 +units=m +no_defs   </AuxStr>      " >> SysUTM.xml
echo "                                                                                                            " >> SysUTM.xml
echo "         </BSC>                                                                                             " >> SysUTM.xml
echo "</SystemeCoord>                                                                                             " >> SysUTM.xml

#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
mm3d XifGps2Txt .*$EXTENSION
#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
mm3d XifGps2Xml .*$EXTENSION RAWGNSS
#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml DN=100
#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
mm3d Tapioca File FileImagesNeighbour.xml 2000
#filter TiePoints (better distribution, avoid clogging)
mm3d Schnaps .*$EXTENSION
#Compute Relative orientation (Arbitrary system)
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH="_mini"
#Visualize relative orientation
mm3d AperiCloud .*$EXTENSION Ori-Arbitrary
#Transform to  RTL system
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL
#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,5] AllFree=1 SH="_mini"
#Visualize Ground_RTL orientation
mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL
#Change system to final cartographic system
mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysUTM.xml Ground_UTM
#Correlation into DEM
if [resol_set]; then
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM ResolTerrain=$RESOL EZA=1
else
	mm3d Malt Ortho ".*.$EXTENSION" Ground_UTM EZA=1
fi
#Mosaic from individual orthos
mm3d Tawny Ortho-MEC-Malt
#PointCloud from Ortho+DEM, with offset substracted to the coordinates to solve the 32bit precision issue
mm3d Nuage2Ply MEC-Malt/NuageImProf_STD-MALT_Etape_8.xml Attr=Ortho-MEC-Malt/Orthophotomosaic.tif Out=OUTPUT/PointCloud_OffsetUTM.ply Offs=[$X_OFF,$Y_OFF,0]

gdal_translate -a_srs "+proj=utm +zone=" $UTM " +ellps=WGS84 +datum=WGS84 +units=m +no_defs" Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/OrthoImage_geotif.tif
gdal_translate -a_srs "+proj=utm +zone=" $UTM " +ellps=WGS84 +datum=WGS84 +units=m +no_defs" MEC-Malt/Z_Num8_DeZoom2_STD-MALT.tif OUTPUT/DEM_geotif.tif
