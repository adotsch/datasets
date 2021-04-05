# 1.6 Billion Taxi Rides

These scripts will download and build a KDB database of the [NYC Taxi and Limousine Commission public taxi ride dataset](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page). The database will only include the yellow taxi data.
The available data for download (as of this writing) is 12 years (2009-2020) and about 1.6 Billion rows.

## Prerequisites

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

Run _q build.q_ to build the HDB. You can use _-s threads_ option to speed up parsing the csv files (useful only when you already have the CSV files). The build script monitors the _watch_ folder and precesses every _yellow_tripdata_*_.csv_ file. Processes files are moved to the _done_ folder.
 
You can run the build script in parallel with the dl script.

