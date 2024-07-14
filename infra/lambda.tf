provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../app/"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lbd_customers_new" {
  function_name = "lbd-customers-new"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_package.output_path

  layers = [
    aws_lambda_layer_version.numpy_layer.arn,
    aws_lambda_layer_version.pyarrow_layer.arn,
    aws_lambda_layer_version.pandas_layer.arn
  ]

  environment {
    variables = {
      S3_BUCKET = "retencaotestebucket",
      S3_FOLDER = "processed/lake/parquet/"
    }
  }
}

resource "aws_lambda_layer_version" "numpy_layer" {
  filename    = "${path.module}/../layers/numpy-layer.zip"
  layer_name  = "python-numpy"
  description = "Lambda Layer Numpy for Python 3.11"
  compatible_runtimes = ["python3.11"]
}

resource "aws_lambda_layer_version" "pyarrow_layer" {
  filename    = "${path.module}/../layers/pyarrow-layer.zip"
  layer_name  = "python-pyarrow"
  description = "Lambda Layer PyArrow for Python 3.11"
  compatible_runtimes = ["python3.11"]
}

resource "aws_lambda_layer_version" "pandas_layer" {
  filename    = "${path.module}/../layers/pandas-layer.zip"
  layer_name  = "python-pandas"
  description = "Lambda Layer Pandas for Python 3.11"
  compatible_runtimes = ["python3.11"]
}
