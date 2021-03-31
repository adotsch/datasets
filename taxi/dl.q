base_url:"https://s3.amazonaws.com/nyc-tlc/trip+data/"
file_temp:"yellow_tripdata_MONTH.csv"

dl:{[m]
	f:ssr[file_temp;"MONTH";ssr[string m;".";"-"]];
	system"wget -c -P download ",base_url,f," && mv download/",f," watch/";
 }':
