# 1.6 Billion Taxi Rides

These scripts will download and build a KDB database of the [NYC Taxi and Limousine Commission public taxi ride dataset](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page). The database will only include the yellow taxi data.
The available data for download (as of this writing) is 12 years (2009-2020) and about 1.6 Billion rows.

## Motivation

Of course it's [Mark Litwintschik's kdb+/q blog post](https://tech.marksblogg.com/billion-nyc-taxi-kdb.html) in his benchmark series. I wanted to get hold on this data in some form, but I didn't want to go through his path as the same source data can be used directly to build a KDB database.

## Prerequisites

 * A modern 32bit or 64bit version of KDB, eg. 3.5-4.0.
 * The scrips are developed for Linux.
 * The downloader uses wget.
 * You will need about 500GB free space for the downloaded CSVs and the uncompressed HDB.

## Quick start

 * Run _q init.q_ and press Enter, or specify number of segments and the path to the segments folder.
 * Run _q dl.q_ and then _dl 2019.01m + til 144_ to start downloading all data between 2009-2020.
 * Run _q build.q_ in parallel with _dl.q_, it will add each month of data to the HDB as it is downloaded.

## Init

Run _q init.q_ to initialize the HDB. First you are asked about the number of segments. Press Enter if you want a simple partitioned HDB, or specify the number of segments and the path to the segments folder. 

The script will create the _zone_id_ table and _par.txt_ (if necessary) in the _db_ folder. It will also clreate the _download, watch_ and _done_ folders.

You can more the db folder to another location if you want, just don't forget to create a _db_ symlink to it.

## Download

Run _q dl.q_ or _q dl.q -s N_ if you want to download on N threads (the console output will be messy).

Use the _dl_ function to download data, eg. _dl 2009.01m + til 12_ will download all data for 2009, or _dl 2019.01m + til 12*12_ will download all data between 2009-2020. 

The script downloads the data into the _download_ folder and moves finished files into the _watch_ folder.

## Build

Run _q build.q_ to build the HDB. You can use _-s threads_ option to speed up parsing the csv files (useful only when you already have the CSV files). The build script monitors the _watch_ folder and precesses every _yellow_tripdata_*_.csv_ file. Processed files are moved to the _done_ folder.
 
You can run the build script in parallel with the dl script, this way the HDB will be ready soon after you finished downloading.

## Enumerations

Some colums are enumeration by design, such as _vendor_name_, _rate_code_, _payment_type_. These columns have their own sym file, so the codes can be changed to proper names in the sym file when the HDB is built.

## Issues encountered

All of the below issues are dealt with in the _build.q_ script.

### Column name variations and different data

Not all of the CSV files have the same column names and the same data. Examples:

In 2009 we have _vendor_name_ and later _vendor_id_. I merged these into _vendor_name_. The [data dictionary](https://www1.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf) helps to identify the meaning of some vendor ids. This column has its own sym file, so the ids can be changed to names when the HDB building is done if necessary.

Before 2016 July the CSVs have pick-up/drop-off longitude/latitude coordinates, later only zone ids. Both are present in the table schema, the _pickup_zone_ and _dropoff_zone_ columns are linked with the _zone_id_ table.

Column name variations, types and prefered colum names are specified at the top of _build.q_ in the [_all_cols_](https://github.com/adotsch/datasets/blob/0a3dffb86434ad4a822758ef00bfa5e9a7f7d4f4/taxi/build.q#L2) table.

### Malformend CSV files

There are empty lines in almost all the CSVs and various extra commas in some of the files. All of this is fixed in the [_cleanx_](https://github.com/adotsch/datasets/blob/cdeacaa9a489d64796318378f4d28db2eecf385a/taxi/build.q#L38) function in _build.q_.

There is a *.out file created during parsing in the watch folder collecting all the lines that don't have the right number of commas and the file is later deleted if it only has one empty line. Currenly this functionlaity has no use because we fixed all the issues, but it may be usefull for spoting issues in future data.

### Issues with timestamps

Some trips seeming go backward in time (Marty McFly?) or take too long. These records are identified in the [_cleant_](https://github.com/adotsch/datasets/blob/cdeacaa9a489d64796318378f4d28db2eecf385a/taxi/build.q#L52) function and moved into the _taxi_dirty_ table.

## Q&A

### How long does it take the build the HDB?

Depends on your CPU and HDD/SSD. It builds in about 2h on my machine (AMD Ryzen 5 2600 Six-Core Processor, 3.4GHz, 16 GB RAM, 1TB Toshiba HDD).

### How to build a HDB with only a subset of the columns?

It is possible to build the HDB from only a subset of the data, but it is also possible to ignore certain colunms. All you have to do is to change the type of the column to be ignored to " " in _build.q_ in the _all_cols_ table at the begining of the script. 

### How to build a compressed HDB?

Just add you line to the _build.q_ script, for example _.z.zd:17 2 1_ will be a good space/speed compromise.
