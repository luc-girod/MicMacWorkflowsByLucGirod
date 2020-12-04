'''
Code from Pybob rearranged to fit my purpose. 

Function to sort GCPs project in Image coordinate system, trhough the one that are outside the image limit, and return a xml file with GCPs per image, name, pixel cooridinates. This xmlfile can then be used wuth mm3d Bascule, and mm3d Campari

'''
import argparse
import lxml.etree as etree
import lxml.builder as builder
import pandas as pd
import gdal
import os

def _argparser():
    parser = argparse.ArgumentParser(description="Combine outputs of XYZ2Im into single xml file for further processing",
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('ij_files', action='store', type=str, nargs='+', help='txt files containing image i,j points')
    parser.add_argument('-o', '--out_file', action='store', type=str, default='MeasuresAuto.xml',
                        help='output filename [AutoMeasures.xml]')
    parser.add_argument('-n', '--no_distortion', action='store_true',
                        help='Use gcp locations computed assuming no distortion to filter GCPs from images.')
    parser.add_argument('-gn', '--GCPname_prefix', type=str, default='')
    return parser

def get_gcp_meas(im_name, meas_name, in_dir, E, nodist=None, GCPname_prefix='GCP'):
    im = gdal.Open(os.path.sep.join([in_dir, im_name]))
    maxj = im.RasterXSize
    maxi = im.RasterYSize

    impts = pd.read_csv(os.path.join(in_dir, meas_name), sep=' ', names=['j', 'i'],dtype='float64')
    if nodist is not None:
        impts_nodist = pd.read_csv(os.path.join(in_dir, nodist), sep=' ', names=['j', 'i'],dtype='float64')

    this_im_mes = E.MesureAppuiFlottant1Im(E.NameIm(im_name))
    for ind, row in impts.iterrows():
        in_im = 0 < row.j < maxj and 0 < row.i < maxi
        if nodist is not None:
            in_nd = -200 < impts_nodist.j[ind]+200 < maxj and -200 < impts_nodist.i[ind] < maxi+200
            in_im = in_im and in_nd
        if in_im:
            this_mes = E.OneMesureAF1I(
                                E.NamePt('{}{}'.format(GCPname_prefix, ind+1)),
                                E.PtIm('{} {}'.format(row['j'], row['i']))
                            )
            this_im_mes.append(this_mes)
    return this_im_mes



def main():
    parser = _argparser()
    args = parser.parse_args()

    E = builder.ElementMaker()
    MesureSet = E.SetOfMesureAppuisFlottants()
    for ij_file in args.ij_files:
        imname = ij_file.split('Auto-')[1].split('.txt')[0]
        if args.no_distortion:
            nodist_file = ij_file.replace('Auto', 'NoDist')
        else:
            nodist_file = None

        print(imname)
        this_meas = get_gcp_meas(imname, ij_file, '.', E, nodist=nodist_file, GCPname_prefix=args.GCPname_prefix)
        MesureSet.append(this_meas)

    tree = etree.ElementTree(MesureSet)
    tree.write(args.out_file, pretty_print=True, xml_declaration=True, encoding="utf-8")


if __name__ == "__main__":
    main()
