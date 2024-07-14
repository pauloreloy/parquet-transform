CREATE EXTERNAL TABLE IF NOT EXISTS my_parquet_table (
    eventType STRING,
    timestamp STRING,
    data STRUCT<
        CustomerID: STRING,
        Name: STRING,
        Balance: STRING
    >
)
STORED AS PARQUET
LOCATION 's3://arquivosgerais/processed-data/parquet/';