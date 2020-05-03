# README



Method to compute DEM from drone flights in reference to a "true" DEM.

Problem: Using the drone internal GPS only leads to a banana effect of the model, and a poor absolute registration.

Methodology:

1. Generate a first rough DEM from the drone images and GPS locations `./DroneNadir.sh -e .JPG -u "32 +north" -r 0.2`
2. use a reference DEM (summer one) to find common points in both (e.g. rocks/boulders). Save two shapefiles `GCP_target.shp` and `GCP_ref.shp` with one column called ID with corresponding names
3. generate a new DEM using these common points as GCPs. This will correct X,Y banana effect. Run 
4. pick points free of snow, of common elevation in both DEMs (reference and DEM from previous step)
5. generate a third iteration of the DEM using these new GCPs to constrain in elevation the model and  

