base_url:"https://s3.amazonaws.com/nyc-tlc/trip+data/"
file_temp:"yellow_tripdata_MONTH.csv"

system"mkdir -p download watch";

dl:{[m]
    f:ssr[file_temp;"MONTH";ssr[string m;".";"-"]];
    system"wget -c -P download ",base_url,f," && mv download/",f," watch/";
 }':

-1 ("";"Download data with:";"q)dl month(s)");
