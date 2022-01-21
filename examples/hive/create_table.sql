CREATE EXTERNAL TABLE IF NOT EXISTS `hive_noaa_gsod_pds_in`(
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
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
LOCATION 's3://noaa-gsod-pds/'
TBLPROPERTIES ('skip.header.line.count'='1');

ALTER TABLE hive_noaa_gsod_pds_in ADD IF NOT EXISTS
  PARTITION (year='2018') LOCATION 's3://noaa-gsod-pds/2018/'
  PARTITION (year='2019') LOCATION 's3://noaa-gsod-pds/2019/'
  PARTITION (year='2020') LOCATION 's3://noaa-gsod-pds/2020/'
  PARTITION (year='2021') LOCATION 's3://noaa-gsod-pds/2021/';