provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}


resource "aws_glue_catalog_database" "paulo" {
  name = "paulo"
}

resource "aws_glue_catalog_table" "paulo_table" {
  database_name = aws_glue_catalog_database.paulo.name
  name          = "paulo_table"

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    columns {
      name = "nome"
      type = "string"
    }

    location      = "s3://arquivosgerais/lake/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    
    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }
  }

  partition_keys {
    name = "id"
    type = "string"
  }

  partition_keys {
    name = "idade"
    type = "int"
  }
}

resource "aws_lakeformation_permissions" "database_permission" {
  depends_on = [ aws_glue_catalog_database.paulo ]
  permissions = ["ALL"]
  principal   = "arn"

  database {
    name          = aws_glue_catalog_database.paulo.name
    catalog_id = data.aws_caller_identity.current.account_id

  }

}