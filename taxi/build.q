//columns (and variations) in the csv's, first one is prefered name, set " " to ignore column
all_cols:ungroup update pc:first'[c], c:((),/:c) from `c`t!/:2 cut (
	`vendor_name`vendor_id`vendorid                              ; "s" ;	// s
	`pickup_datetime`trip_pickup_datetime`tpep_pickup_datetime   ; "z" ;    // z
	`dropoff_datetime`trip_dropoff_datetime`tpep_dropoff_datetime; "z" ;    // z
	`passenger_count                                             ; "h" ;    // h
	`trip_distance                                               ; "f" ;    // f
	`pickup_longitude`start_lon                                  ; "f" ;    // f
	`pickup_latitude`start_lat                                   ; "f" ;    // f
	`dropoff_longitude`end_lon                                   ; "f" ;    // f
	`dropoff_latitude`end_lat                                    ; "f" ;    // f
	`pickup_zone`pulocationid                                    ; "j" ;    // j
	`dropoff_zone`dolocationid                                   ; "j" ;    // j
	`rate_code`ratecodeid                                        ; "s" ;    // s
	`store_and_forward`store_and_fwd_flag                        ; "c" ;    // c
	`payment_type                                                ; "s" ;    // s
	`fare_amt`fare_amount                                        ; "f" ;    // f
	`extra                                                       ; "f" ;    // f
	`mta_tax                                                     ; "f" ;    // f
	`tip_amt`tip_amount                                          ; "f" ;    // f
	`tolls_amt`tolls_amount                                      ; "f" ;    // f
	`total_amt`total_amount                                      ; "f" ;    // f
	`surcharge                                                   ; "f" ;    // f
	`improvement_surcharge                                       ; "f" ;    // f
	`congestion_surcharge                                        ; "f" );   // f

//col type map
ct:exec c!t from all_cols
//preferred col names
cp:exec c!pc from all_cols

//taxi schema
taxi:exec flip pc!(t$\:()) from select distinct pc,t from all_cols where " "<>t;

cleanxout:0

//prepare/fix raw txt data before parsing
cleanx:{[m;n;x]
	x:$[x[0]like"[vV]endor*";1_x;x];			//remove csv header
	if[m within 2010.02 2010.03m;				//remove extra commas
		x:ssr[;"1,,,";"1,,"]':[x]];
	if[m within 2016.07 2016.12m;				//remove extra trailing commas
		x[i]:-2_'x[i:where x like "*,,"]];
	neg[cleanxout] x where not v:n=sum'[","=x];	//save dirty txt
	x where v									//keep lines with n commas
 }

//parse txt into table
parsex:{[c;t;x]flip c!(t;",")0:x}

//clean/prepare table before upserting into hdb
cleant:{[m;t]
	t:taxi upsert t;														//missing cols
	t:update dirty:1b from t where m<"m"$pickup_datetime;
	t:update dirty:1b from t where m>"m"$dropoff_datetime;
	t:update dirty:1b from t where pickup_datetime>dropoff_datetime;
	t:update dirty:1b from t where dropoff_datetime>pickup_datetime+0.5;	//12h longer trips?
	:t
 }

//manage enumerations
enumt:{[t]
	c:cols t;
	if[`vendor_name  in c; t:update `:db/vendor_name?vendor_name   from t];
	if[`rate_code    in c; t:update `:db/rate_code?rate_code       from t];
	if[`payment_type in c; t:update `:db/payment_type?payment_type from t];
	if[`pickup_zone  in c; t:update `zone_id!pickup_zone           from t];
	if[`dropoff_zone in c; t:update `zone_id!dropoff_zone          from t];
	:t
 }

//partition path with / at the end
ppath:{[d].Q.dd[.Q.par[`:db;d;`taxi];`]}

//parse/clean/upsert raw data
f:{[m;c;t;x]
	t:enumt .Q.fc[{[m;c;t;x]cleant[m] parsex[c;t] cleanx[m;count[t]-1] x}[m;c;t]] x;
	`:db/taxi_dirty/ upsert ``dirty _ update source_month:m from select from t where dirty;
	t:`date xgroup update date:"d"$pickup_datetime from ``dirty _ select from t where not dirty;
	{ppath[first value x] upsert flip y}'[key t;value t];
 }

//csv input buffer
buff: 200*1024*1024

loadcsv:{[fn]
	t0:.z.p;
	-1 string[.z.z]," - Processing ",fn;
	m:get @[;4;:;"."](7#-11#fn),"m";								//month
	h:`$","vs lower{(min x?"\r\n")#x}"c"$read1(hsym`$fn;0;1000);	//csv header
	if[any not h in key ct;bp;'"Unsupported csv: ",fn];
	cleanxout::hopen d:hsym`$fn,".out";								//txt dirt into .out
	.Q.fsn[f[m;cp h where " "<>ct h;ct h];hsym`$fn;buff];			//stream-proceccing the csv
	hclose cleanxout;if[2>hcount d;hdel d];							//remove empty .out
	t1:.z.p;
	-1 string[.z.z]," - Done! (",string["i"$"v"$t1-t0],"s)";
	`:db/build upsert enlist`fn`t0`t1!(`$fn;t0;t1);					//save build time
 }

.z.ts:{
	dir:{x where x like "yellow_tripdata_*.csv"}system"ls watch";
	if[count dir;
		loadcsv f:"watch/",first dir;
		system"mv ",f," done/";
	];
 }
 
-1 "Monitoring the watch folder ...";

\t 500
