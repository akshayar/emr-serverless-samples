SET hive.cli.print.header=true;
SET hive.query.name=ExtremeWeather;
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=non-strict;

DROP TABLE IF  EXISTS `hive_noaa_gsod_pds_out` ;

CREATE TABLE IF NOT EXISTS `hive_noaa_gsod_pds_out`(
  `station` string,
  `date` string,
  `latitude` string,
  `longitude` string,
  `elevation` string,
  `name` string,
  `temp` string,
  `temp_attributes` string,
  `dewp` string,
  `dewp_attributes` string,
  `slp` string,
  `slp_attributes` string,
  `stp` string,
  `stp_attributes` string,
  `visib` string,
  `visib_attributes` string,
  `wdsp` string,
  `wdsp_attributes` string,
  `mxspd` string,
  `gust` string,
  `max` string,
  `max_attributes` string,
  `min` string,
  `min_attributes` string,
  `prcp` string,
  `prcp_attributes` string,
  `sndp` string,
  `frshtt` string)
PARTITIONED BY (`year` string)
STORED AS PARQUET ;

INSERT INTO TABLE hive_noaa_gsod_pds_out partition(`year`)
SELECT `station` ,  `date` ,  `latitude` ,  `longitude` ,  `elevation` ,  `name` ,  `temp` ,
       `temp_attributes` ,  `dewp` ,  `dewp_attributes` ,  `slp` ,  `slp_attributes` ,  `stp` ,
       `stp_attributes` ,  `visib` ,  `visib_attributes` ,  `wdsp` ,  `wdsp_attributes` ,  `mxspd` ,
       `gust` ,  `max` ,  `max_attributes` ,  `min` ,  `min_attributes` ,  `prcp` ,  `prcp_attributes` ,
       `sndp` ,  `frshtt` , `year`
FROM hive_noaa_gsod_pds_in where `year` = '2021';

DROP TABLE IF  EXISTS `hive_noaa_gsod_pds_aggregate` ;

CREATE TABLE IF NOT EXISTS `hive_noaa_gsod_pds_aggregate`(
  `station` string,
  `latitude` string,
  `longitude` string,
  `name` string,
  `year` string,
  `maxtemp` string,
  `mintemp` string,
  `maxdiff` string,
  `mindiff` string )
STORED AS PARQUET ;



INSERT INTO TABLE hive_noaa_gsod_pds_aggregate
select `station`,`latitude`,`longitude`,`name`,`year`,
max(`max`) maxtemp, min(`min`) mintemp,max(`max`-`min`) maxdiff, min(`max`-`min`) mindiff
from hive_noaa_gsod_pds_out
group by `station`,`latitude`,`longitude`,`name`,`year` ;




