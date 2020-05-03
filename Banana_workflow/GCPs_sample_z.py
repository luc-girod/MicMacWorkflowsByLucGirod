import gdal
import numpy as np
import geopandas as gpd
import pandas as pd
import argparse


def _argparser():
    parser = argparse.ArgumentParser(description="Sample Raster Z-value from shapefile (X,Y points)",
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-r','--raster', action='store', type=str, help='path to raster file to sample')
    parser.add_argument('-s','--shapefile', type=str, help='path to shapefile with X,Y coordinates')
    parser.add_argument('-o', '--out_file', action='store', type=str, default='GCPs.csv',
                        help='output filename, either csv, or xyz')
    parser.add_argument('-gn', '--GCPname_prefix', type=str, default='', help='')
    return parser


def get_pt_value_rasterfile(rasterfile, Xs, Ys):
  gdata = gdal.Open(rasterfile)
  gt = gdata.GetGeoTransform()
  data = gdata.ReadAsArray().astype(np.float)
  gdata = None
  x = (Xs - gt[0])/gt[1]
  y = (Ys - gt[3])/gt[5]
  print(x.__len__())
  return data[y.astype('int'), x.astype('int')]

def main():
    parser = _argparser()
    args = parser.parse_args()
    
    shp = gpd.read_file(args.shapefile)
    shp['X'] = shp.geometry.x
    shp['Y'] = shp.geometry.y
    shp.drop(columns='geometry', inplace=True)
    shp['Z'] = get_pt_value_rasterfile(args.raster, shp.X, shp.Y)
    shp.sort_values(by='id', inplace=True)
    shp.id = args.GCPname_prefix + shp.id.astype(str)
    if args.out_file.split('.')[-1] == 'csv':
        shp.to_csv(args.out_file, columns=['X','Y','Z','id'], header='#F=X Y Z N',index=False, sep=' ')
    if args.out_file.split('.')[-1] == 'xyz':
        shp.to_csv(args.out_file, columns=['X','Y','Z','id'], header=False,index=False, sep=' ')
    print('Done')
    
    
    

if __name__ == "__main__":
    main()
