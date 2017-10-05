# Padding 

The time-interpolation service of GFDL's "data manager" only works correctly
within single files.

The size of some datasets makes it impractical to put all time records in a
single file so we often provide files for recognizable time periods like, for
example, a year.
This means that if the first record is, say, at 6am on Jan 1st in a file for
1979, there is not enough data in one file to interpolate correctly to, say,
3am because the previous record is another file.
To overcome this limitation, we "pad" the files with the last and first records
of the previous and subsequent files.

The JRA55-do data is one such dataset and this `Makefile` creates the padded
version of the files needed to drive MOM6 in ice-ocean mode.

## Usage

To generate the padded files, make sure the `nco` utilities are in you path.
Then type:
```bash
make
```

To check that the generated files have the right checksum
```bash
make check
```

To remake the md5sums.txt checksum file:
```bash
make md5
```

## Requirements

The gnu Makefile uses `ncks` and `ncrcat` from the
[nco](http://nco.sourceforge.net/) netcdf-utilities package.
Use versions later than 4.2.1 to ensure the files are bitwise reproducible.

## Checksums

The JRA55-do data uses the "classic" netcdf format which does not have
non-reproducible bits associated with the later formats.
All this operation does is concatenate data. There are no floating point
operations.
This means that if we have no tool-version or date-dependent attributes added
by the tools then the padded files can be bitwise reproduced which allows us to
record the checksums.
To achieve this, we us the "-h" command-line option for `ncks` and `ncrcat`
which inhibits adding the global "history" attribute to the meta-data.

## Timings

- Creating the padded files is ~1 hour using a single thread.
- Creating checksums is ~1 hour.
- Checking checksums is ~1 hour.
