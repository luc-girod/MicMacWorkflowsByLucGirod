The DroneNadir workflow
=======================

This workflow is designed for drone images taken at nadir (or close to nadir) containing GNSS location data. It was created and tested using images from a DJI Mavic Pro and should run for all similar drones (other DJI products for instance), and also for more "serious" aerial photography systems.

Expected data input
###################

First, I would like to remind users that an along-track overlap of 80% and across track overlap of 60% are the minimum recommended values when flying a survey.

Secondly, the only input requiered for this workflow is images that include a geolocation tag in their EXIF metadata.

The current version of the script only supports UTM zones as output coordinate system. It can easily adapted to run any EPSG code.

Running the script
###################

From the included help
::
	usage: DroneNadir.sh -e JPG -x 55000 -y 6600000 -u "32 +north" -p true -r 0.05
	    -e EXTENSION     : image file type (JPG, jpg, TIF, png..., default=JPG).
	    -x X_OFF         : X (easting) offset for ply file overflow issue (default=0).
	    -y Y_OFF         : Y (northing) offset for ply file overflow issue (default=0).
	    -u UTMZONE       : UTM Zone of area of interest. Takes form 'NN +north(south)'
	    -v PROJ          : PROJ.4 string for coordinate system of output (use if not UTM)
	    -s SH            : Do not use 'Schnaps' optimised homologous points.
	    -p do_ply        : use to NOT export ply file.
	    -c regul         : use to activate color equalization in mosaicking (only do with good camera, eg NOT DJI).
	    -a do_AperiCloud : use to NOT export AperiCloud file.
	    -o obliqueFolder : Folder with oblique imagery to help orientation (will be entierely copied then deleted during process).
	    -r RESOL         : Ground resolution (in meters)
	    -z ZoomF         : Last step in pyramidal dense correlation (default=2, can be in [8,4,2,1])
	    -t Clean-up      : Remove most temporary files after the process is over (Option 0(default)=no 1=allows for further processing 2=keep only final files)
	    -h               : displays this message and exits.

More details for some select options:

* `-x` and `-y` define an offset so the exported 32bits ply files do not have an overflow issue and round the points' coordinates. Without them, the point cloud would appear with lines of points at regular intervals much higher than the expected pitch. The exact values here don't matter very much, but "somewhere in the survey domain" is the recommendation. The coordinates need to be given in the same system as the export system (defined next with -u).
* `-u` defined the UTM zone of the final products. The format is "NN +hemisphere", so, for UTM32N (EPSG:32632), the expected value is `"32 +north"`, and for UTM5S (EPSG:32705) `"5 +south"`.
* `-v` offers an option to use any projection system that PROJ.4 can use. You then have to put a full proj string, for instance for UTM32N : `"+proj=UTM +zone=32 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs"`
* `-s` Schnaps is a tie point optimiser that reduces the amount of tie points while optimising their distributions in the images. It also removes images that do not have enough tie points. It is **switch on** by default.
* `-p` By default, the workflow exports a point cloud of the final DEM. You can suppress that functionnality with this option.
* `-c` By default, the mosaicking of the individually orthorectified images is done without any colour balancing and equalization. This is because MicMac is pretty bad at this and often produces rather poor results.
* `-a` Like -p, but for the low density point cloud made from the tie points.
* `-o` Option to add non-nadir imagery in the orientation to improve the relative accuracy of the model and avoid the banana/doming effect. These images have to be in a subfolder, and need to satisfy the same requierment than the main set.
* `-r` Forces the GSD (Ground Sampling Distance) of the final product to be fixed to a user chosen value instead of being automatically chosen. This is mostly usefull if the product is to be compared with another product. The resolution given here will be the one of the orthoimage, and the one of the DEM if the next option `-z` is equal to 1. The GSD of the DEM is multiplied by the value of `-z` (def 2).
* `-z` Defines the last step of the dense correlation. At 1, the images are used at full resolution in the correlation step, which is usually a waste of time when using colour images coming from a bayer matrix sensor, as the real resolution is closer to half of the nominal value. That is why the **default is 2**. Indreasing the value to 4 or 8 will make the process faster and yield a lower resolution model, potentially more complete in some cases.
* `-t` The cleanup options allow to automatically remove temporary files with different level of clean, from no cleanup to complete cleanup only leaving the input and output data. The intermediate option `-t 1` allows the user to conduct further processing of the data, such as adding GCPs, trying different correlation parameters, changing orthomosaicking approach and so on.




