# rJourney
FHWA National long distance passenger model

[![Build Status](https://dev.azure.com/ResourceSystemsGroup/Modeling%20Software/_apis/build/status/RSGInc.rJourney?branchName=master)](https://dev.azure.com/ResourceSystemsGroup/Modeling%20Software/_build/latest?definitionId=8&branchName=master)

### Download the HDF5 library, command line model, and input files
  - Select Clone or Download and then Download Zip
  - Download the [large inputs file](https://github.com/RSGInc/rJourney_resources/raw/master/inputs.zip)
  - Download and install [hdf5-1.8.19-Std-win10_64-vs2015.zip](https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.19/bin/windows/hdf5-1.8.19-Std-win10_64-vs2015.zip)
  - Optional: Download the [text versions](https://github.com/RSGInc/rJourney_resources/raw/master/text_inputs.zip) of the input matrices (default is OMX)
  - Optional: Download the [500-zone sample household file](https://github.com/RSGInc/rJourney_resources/blob/master/azure_inputs/us_synpop_hh3_500_zone_sample.dat) for faster runtime

### Optional: Build rJourney from source
  - Install the [Free Pascal Compiler](https://sourceforge.net/projects/freepascal/)
    - Make sure to use the 64-bit version since the 32-bit version won't work
  - Compile rJourney:
    - Open Command Prompt in the project folder
    - run `fpc -Mdelphi -Ci -CR -Sh rJourney_1_4.pas`

### Run rJourney
  - Unzip the inputs into the project folder, and create a new empty directory named 'outputs'
  - Open Command Prompt in the project folder
  - Add the HDF5 library to your system path: `path=C:\Program Files\HDF_Group\HDF5\1.8.19\bin\;%PATH%`.
  - run `rJourney_1_4.exe .\rJourney_example_config.txt`

## Documentation
  - Additional resources, example configs, and documentation can be found at [rJourney_resources](https://github.com/rsginc/rjourney_resources)
  - Note that rJourney only runs on Windows 64-bit machines
  - If modifying any input files or creating your own, note that
    - All matrix input values must be less than or equal to the unsigned 2-byte integer maximum of 65,534, and
    - Only OMX files with float/double matrix values will work properly

## Acknowledgements
Special thanks to [Jeff Newman](https://github.com/jpn--) of Cambridge Systematics for building the [Free Pascal OMX library](https://github.com/jpn--/omx-freepascal), and to [Andrey Paramonov](http://hdf-forum.184993.n3.nabble.com/Delphi-interface-for-hdf5-dll-1-8-19-amp-1-10-1-td4029751.html) for creating the HDF5 library wrapper for Pascal.
