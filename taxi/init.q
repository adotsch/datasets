system"mkdir -p db download watch done";
1"Number of segments? (default:1) ";n:parse read0 0;if[n~(::);n:1];
if[1<n;
	sd:system["cd"],"/segments";
	1"Segment directory (abs path, default:",sd,")? ";s:read0 0;if[s~"";s:sd];
	`:db/par.txt 0: (s,"/"),/:string til n];

z:`zone_id`borough`zone`service_zone xcol ("jsss";1#csv)0:`$":meta/taxi_zone_lookup.csv"
z:`zone xkey `zone_id xasc z upsert (0;`Unknown;`NA;`$"N/A")
`:db/zone_id set z;

\\