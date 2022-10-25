#Workflow MICMAC for Thermal drone survey
#
# Luc Girod, University of Oslo - luc.girod@geo.uio.no


#This file is a workflow for drone THERMAL images taken at nadir (or close to nadir) containing GNSS location data. It was created and tested using images from a DJI H20T and should run for all similar drones (other DJI products for instance).
# The input data needs to be an integer tif file in centiKelvin (0°C=273150cK)

# example:
# ./DroneNadir_TapiocaFull.sh -e tif -u "32 +north"  -n H20T_Test



# add default values
EXTENSION=JPG
X_OFF=0;
Y_OFF=0;
PROJ_set=false
do_ply=false
do_AperiCloud=false
use_Schnaps=true
resol_set=false
ZoomF=2
obliqueFolder=none
regul=0
CleanUp=0
NamePrefix=DroneNadir
GNSS_Q=0.05
DN=100

while getopts "e:x:y:u:v:g:sd:pcao:r:z:t:n:h" opt; do
  case $opt in
    h)
      echo "Run the workflow for drone acquisition at nadir (and pseudo nadir) angles)."
      echo "usage: DroneNadir.sh -e JPG -x 55000 -y 6600000 -u \"32 +north\" -p true -r 0.05"
      echo "	-e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG)."
      echo "	-x X_OFF         : X (easting) offset for ply file overflow issue (default=0)."
      echo "	-y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0)."
      echo "	-u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'"
      echo "	-v PROJ          : PROJ.4 string for coordinate system of output (use if not UTM)"
      echo "	-g GNSS_Q        : Quality of embedded GNSS (in m, Def=0.05m, right for good RTK data)"
      echo "	-s SH            : Do not use 'Schnaps' optimised homologous points."
      echo "	-d DN            : Max distance between camera for tie point search (default=100, in m)."
      echo "	-p do_ply        : use to export ply file."
      echo "	-c regul         : use to activate color equalization in mosaicking (only do with good camera, eg NOT DJI)."
      echo "	-a do_AperiCloud : use to export AperiCloud file."
      echo "	-o obliqueFolder : Folder with oblique imagery to help orientation (will be entierely copied then deleted during process)."
      echo "	-r RESOL         : Ground resolution (in meters)"
      echo "	-z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])"
      echo "	-t Clean-up      : Remove most temporary files after the process is over (Option 0(default)=no 1=keep Correlation and ortho folders, 2=allows for further processing 3=keep only final files)"
      echo "	-n NamePrefix    : name of scene (used as prefix in the output, default=DroneNadir)."
      echo "	-h	             : displays this message and exits."
      echo " "
      exit 0
      ;;   
	e)
      EXTENSION=$OPTARG
      ;;
	u)
      PROJ="+proj=utm +zone=$OPTARG +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
      proj_set=true
      ;; 
	v)
      PROJ=$OPTARG
      proj_set=true
      ;; 
	g)
      GNSS_Q=$OPTARG
      ;;  
	r)
      RESOL=$OPTARG
      resol_set=true
      ;; 
	s)
      use_Schnaps=false
      ;;  
	d)
      DN=$OPTARG
      ;;   	
    p)
      do_ply=true
      ;;   	
    c)
      regul=1
      ;; 
    a)
      do_AperiCloud=true
      ;; 
	o)
      obliqueFolder=$OPTARG
      ;;
	x)
      X_OFF=$OPTARG
      ;;	
	y)
      Y_OFF=$OPTARG
      ;;	
	z)
      ZoomF=$OPTARG
      ;;	
	t)
      CleanUp=$OPTARG
      ;;	
	n)
      NamePrefix=$OPTARG
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
if [ "$proj_set" = false ]; then
	echo "Projection system not set"
	exit 1
fi
if [ "$use_Schnaps" = true ]; then
	echo "Using Schnaps!"
	SH="_mini"
else
	echo "Not using Schnaps!"
	SH=""
fi
#create PROJ file (after deleting any existing one)
rm SysPROJ.xml
echo "<SystemeCoord>                                                                                              " >> SysPROJ.xml
echo "         <BSC>                                                                                              " >> SysPROJ.xml
echo "            <TypeCoord>  eTC_Proj4 </TypeCoord>                                                             " >> SysPROJ.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysPROJ.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysPROJ.xml
echo "            <AuxR>       1        </AuxR>                                                                   " >> SysPROJ.xml
echo "            <AuxStr>  "$PROJ"   </AuxStr>                                                                   " >> SysPROJ.xml
echo "                                                                                                            " >> SysPROJ.xml
echo "         </BSC>                                                                                             " >> SysPROJ.xml
echo "</SystemeCoord>                                                                                             " >> SysPROJ.xml


#Copy everything from the folder with oblique images
if [ "obliqueFolder" != none ]; then
	cp $obliqueFolder/* .
fi

#Convert all images to tif (BW and RGB) for use in AperiCloud (because it otherwise breaks if too many CPUs are used)
if [ "$do_AperiCloud" = true ]; then
	DevAllPrep.sh
fi

#Making OUTPUT folder
mkdir OUTPUT


#Get the GNSS data out of the images and convert it to a txt file (GpsCoordinatesFromExif.txt)
echo "mm3d XifGps2Txt .*$EXTENSION"
mm3d XifGps2Txt .*$EXTENSION

#Get the GNSS data out of the images and convert it to a xml orientation folder (Ori-RAWGNSS), also create a good RTL (Local Radial Tangential) system.
echo "mm3d XifGps2Xml .*$EXTENSION RAWGNSS"
mm3d XifGps2Xml .*$EXTENSION RAWGNSS

#Use the GpsCoordinatesFromExif.txt file to create a xml orientation folder (Ori-RAWGNSS_N), and a file (FileImagesNeighbour.xml) detailing what image sees what other image (if camera is <50m away with option DN=50)
echo "mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml DN=$DN OkNoIm=1"
mm3d OriConvert "#F=N X Y Z" GpsCoordinatesFromExif.txt RAWGNSS_N ChSys=DegreeWGS84@RTLFromExif.xml MTD1=1 NameCple=FileImagesNeighbour.xml DN=$DN OkNoIm=1

#Find Tie points using 1/2 resolution image (best value for RGB bayer sensor)
#Find half size of image:
firstIm=$(ls *.$EXTENSION | head -n1)
halfsize=$(expr $(exiftool -s3  -ImageWidth $firstIm) / 2)
echo "mm3d Tapioca File FileImagesNeighbour.xml "$halfsize
mm3d Tapioca File FileImagesNeighbour.xml -1

if [ "$use_Schnaps" = true ]; then
	#filter TiePoints (better distribution, avoid clogging)
    echo "mm3d Schnaps .*$EXTENSION MoveBadImgs=1"	
    mm3d Schnaps .*$EXTENSION MoveBadImgs=1
fi

#Compute Relative orientation (Arbitrary system)
echo "mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=$SH"
mm3d Tapas FraserBasic .*$EXTENSION Out=Arbitrary SH=$SH

#Visualize relative orientation, if apericloud is not working, run 
if [ "$do_AperiCloud" = true ]; then
    echo "mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=$SH "	
    mm3d AperiCloud .*$EXTENSION Ori-Arbitrary SH=$SH Out=OUTPUT/$NamePrefix.AperiCloud_Arbitrary.ply
fi

#Transform to  RTL system
echo "mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL"
mm3d CenterBascule .*$EXTENSION Arbitrary RAWGNSS_N Ground_Init_RTL

#Bundle adjust using both camera positions and tie points (number in EmGPS option is the quality estimate of the GNSS data in meters)
echo "mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,5] AllFree=1 SH=$SH"
mm3d Campari .*$EXTENSION Ground_Init_RTL Ground_RTL EmGPS=[RAWGNSS_N,$GNSS_Q] AllFree=1 SH=$SH

#Visualize Ground_RTL orientation
if [ "$do_AperiCloud" = true ]; then
    echo "mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=$SH"	
    mm3d AperiCloud .*$EXTENSION Ori-Ground_RTL SH=$SH Out=OUTPUT/$NamePrefix.AperiCloud_Ground_RTL.ply
fi
#Change system to final cartographic system
echo "mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysPROJ.xml Ground_PROJ"
mm3d ChgSysCo  .*$EXTENSION Ground_RTL RTLFromExif.xml@SysPROJ.xml Ground_PROJ

#Print out a text file with the camera positions (for use in external software, e.g. GIS)
echo "mm3d OriExport Ori-Ground_PROJ/O.*xml CameraPositionsPROJ.txt AddF=1"
mm3d OriExport Ori-Ground_PROJ/O.*xml CameraPositionsPROJ.txt AddF=1

#Taking away files from the oblique folder
if [ "$obliqueFolder" != none ]; then	
	here=$(pwd)
	cd $obliqueFolder	
	find ./ -type f -name "*" | while read filename; do
		f=$(basename "$filename")
		rm  $here/$f
	done	
	cd $here	
fi


#Correlation into DEM
if [ "$resol_set" = true ]; then
    echo "mm3d Malt Ortho ".*.$EXTENSION" Ground_PROJ ResolTerrain=$RESOL EZA=1 ZoomF=$ZoomF"	
    mm3d Malt Ortho ".*.$EXTENSION" Ground_PROJ ResolTerrain=$RESOL EZA=1 ZoomF=$ZoomF
else
    echo "mm3d Malt Ortho ".*.$EXTENSION" Ground_PROJ EZA=1 ZoomF=$ZoomF"	
    mm3d Malt Ortho ".*.$EXTENSION" Ground_PROJ EZA=1 ZoomF=$ZoomF
fi

#Mosaic from individual orthos
echo "mm3d Tawny Ortho-MEC-Malt RadiomEgal=$regul"
mm3d Tawny Ortho-MEC-Malt RadiomEgal=$regul


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
	echo "gdal_translate -a_srs \""$PROJ\"" $lastDEM tmp_geo.tif"
	gdal_translate -a_srs "$PROJ" $lastDEM tmp_geo.tif
	echo "gdal_translate -a_srs \""$PROJ\"" -a_nodata 0 $lastmsk tmp_msk.tif"
	gdal_translate -a_srs "$PROJ" -a_nodata 0 $lastmsk tmp_msk.tif
	echo "gdal_calc.py -A tmp_msk.tif -B tmp_geo.tif --outfile=../OUTPUT/"$NamePrefix".DEM_geotif.tif --calc=\"B*(A>0)\" --NoDataValue=-9999"
	gdal_calc.py -A tmp_msk.tif -B tmp_geo.tif --outfile=../OUTPUT/$NamePrefix.DEM_geotif.tif --calc="B*(A>0)" --NoDataValue=-9999
	rm tmp_geo.tif tmp_msk.tif
	#PointCloud from Ortho+DEM, with offset substracted to the coordinates to solve the 32bit precision issue
	if [ "$do_ply" = true ]; then
		echo "mm3d Nuage2Ply "$lastNuageImProf" Attr=Ortho-MEC-Malt/Orthophotomosaic.tif Out=../OUTPUT/PointCloud_OffsetPROJ.ply Offs=[$X_OFF,$Y_OFF,0]"	
		mm3d Nuage2Ply $lastNuageImProf Attr=../Ortho-MEC-Malt/Orthophotomosaic.tif Out=../OUTPUT/$NamePrefix.PointCloud_OffsetPROJ.ply Offs=[$X_OFF,$Y_OFF,0]
	fi
cd ..

echo "gdal_translate  -a_nodata 0 -a_srs \""$PROJ\"" MEC-Malt/$lastcor OUTPUT/"$NamePrefix".CORR.tif"
gdal_translate  -a_nodata 0 -a_srs "$PROJ" MEC-Malt/$lastcor OUTPUT/$NamePrefix.CORR.tif
echo "gdal_translate -a_srs \""$PROJ\"" Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/"$NamePrefix".OrthoImage_geotif.tif"
gdal_translate -a_srs "$PROJ" Ortho-MEC-Malt/Orthophotomosaic.tif OUTPUT/$NamePrefix.OrthoImage_centiK_geotif.tif -ot Float32
gdal_calc.py -A OUTPUT/$NamePrefix.OrthoImage_centiK_geotif.tif  --outfile=OUTPUT/$NamePrefix.OrthoImage_Celcius_geotif.tif --calc="(A/100)-273.15"

echo "Cleaning up with option "$CleanUp""
if [ "$CleanUp" = 1 ]; then
	rm -r Ori-InterneScan Ori-Arbitrary Ori-Ground_Init_RTL Ori-RAWGNSS Ori-RAWGNSS_N Pyram SauvApero.xml Schnaps_poubelle.txt WarnApero.txt MkDevlop DevAll.sh
elif [ "$CleanUp" = 2 ]; then
	rm -r Ori-InterneScan Ori-Arbitrary Ori-Ground_Init_RTL Ori-RAWGNSS Ori-RAWGNSS_N MEC-Malt Ortho-MEC-Malt Pyram SauvApero.xml Schnaps_poubelle.txt WarnApero.txt MkDevlop DevAll.sh
elif [ "$CleanUp" = 3 ]; then
	rm -r Tm* Ori-InterneScan Ori-Arbitrary Ori-Ground_Init_RTL Ori-RAWGNSS Ori-RAWGNSS_N MEC-Malt Ortho-MEC-Malt Pyram SauvApero.xml Schnaps_poubelle.txt WarnApero.txt MkDevlop DevAll.sh Homol* Pastis
fi
