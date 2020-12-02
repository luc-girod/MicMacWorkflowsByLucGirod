Installation and Setup
=======================

The following is a (non-exhaustive) set of instructions for getting setup to run MicMac on your own machine. Note
that MicMac can be an **extremely** computationally intensive process, so we don't really recommend trying to run this on your
personal laptop.

As this is a (non-exhaustive) set of instructions, it may not work 100% with your particular setup.
We are happy to try to provide guidance/support, **but we make no promises**.

Getting the scripts
###################

To get those scripts, you can download the current version from https://github.com/luc-girod/MicMacWorkflowsByLucGirod
or clone with:
::

	git clone https://github.com/luc-girod/MicMacWorkflowsByLucGirod


Installing MicMac
#################

Detailed installation instructions for MicMac on multiple platforms can be found `here <https://micmac.ensg.eu/index.php/Install/>`_,
but we've added a short summary to help guide through the process.

First, clone the MicMac repository to a folder on your computer (you can also do this online via github):
::

    /home/bob/software:~$ git clone https://github.com/micmacIGN/micmac.git
    ...
    /home/bob/software:~$ cd micmac
    /home/bob/software/micmac:~$ git fetch
    /home/bob/software/micmac:~$ git checkout IncludeALGLIB

This will clone the MicMac git repository to your machine, fetch the remote, and switch to the *IncludeALGLIB* branch.
Check the **README.md** (or **LISEZMOI.md**) file to install any dependencies, then:
::

    /home/bob/software/micmac:~$ mkdir build && cd build/
    /home/bob/software/micmac/build:~$ cmake .. -DWITH_QT5=1 -DWERROR=0 -DWITH_CCACHE=OFF
    ...
    /home/bob/software/micmac/build:~$ make install -j$n

where $n is the number of cores to compile MicMac with. The compiler flag **-DWERROR=0** is needed, as some of the dependencies
will throw warnings that will force the compiler to quit with errors if we don't turn it off.

Finally, make sure to add the MicMac bin directory (/home/bob/software/micmac/bin in the above example) to your $PATH
environment variable, in order to be able to run MicMac. You can check that all dependencies are installed by running
the following:
::

    /home/bob:~$ mm3d CheckDependencies
    git revision : v1.0.beta13-844-g21d990533

    byte order   : little-endian
    address size : 64 bits

    micmac directory : [/home/bob/software/micmac/]
    auxilary tools directory : [/home/bob/software/micmac/binaire-aux/linux/]

    --- Qt enabled : 5.9.5
        library path:  [/home/bob/miniconda3/envs/bobtools/plugins]

    make:  found (/usr/bin/make)
    exiftool:  found (/usr/bin/exiftool)
    exiv2:  found (/usr/bin/exiv2)
    convert:  found (/usr/bin/convert)
    proj:  found (/usr/bin/proj)
    cs2cs:  found (/usr/bin/cs2cs

You should also see the following output from the **mm3d SateLib ApplyParallaxCor** command:
::

    /home/bob:~$ mm3d SateLib ApplyParallaxCor
    *****************************
    *  Help for Elise Arg main  *
    *****************************
    Mandatory unnamed args :
      * string :: {Image to be corrected}
      * string :: {Paralax correction file}
    Named args :
      * [Name=Out] string :: {Name of output image (Def=ImName_corrected.tif)}
      * [Name=FitASTER] INT :: {Fit functions appropriate for ASTER L1A processing (input '1' or '2' : version number)}
      * [Name=ExportFitASTER] bool :: {Export grid from FitASTER (Def=false)}
      * [Name=ASTERSceneName] string :: {ASTER L1A Scene name (Only for and MANDATORY for FitASTERv2)}

In a nutshell, the basic idea is: clone the MicMac git repository, then build the source code. Simple!

Adding the scripts to your path
###############################

The folder where the scripts are downloaded on your machine (or where you cloned the depository) neds to be added to your path so the scripts can be called from anywhere. This is system dependent, and Google will be your fiend, just search "adding a folder to path on XXXXX" where XXXXX is your OS.

Optional: Preparing a python environment
########################################

If you like, you can set up a dedicated python environment for your MicMac needs as some scripts rely on Python. This can be handy, in case any
packages required by these scripts clash with packages in your default environment. Our personal preference is `conda <https://docs.conda.io/en/latest/>`_,
but your preferences may differ.

The git repository has a file, micmac_env.yml, which provides a working environment for pymmaster and conda.
Once you have conda installed, simply run:
::

    conda-env create -f micmac_env.yml

This will create a new conda environment, called micmac_env, which will have all of the various python packages
necessary to run pymmaster. To activate the new environment, type:
::

    conda activate micmac_env

And you should be ready to go.

If you don't manage to go through this tutorial, feel free to ask for help by sending an e-mail, though it can also be helpful to google around
for some solutions first. If you do send us an e-mail, be sure to include the specific error messages that you receive.
Screenshots are also helpful.

Good luck!