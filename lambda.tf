data "template_file" "lambda" {
  template = file("${path.module}/lambda/index.template.js")
  vars = {
    version             = var.version_name
    bucket_name         = aws_s3_bucket.mc_app.bucket
    bucket_region       = aws_s3_bucket.mc_app.region
    external_api_url    = var.external_api_url
    application_name    = var.application_name
    entrypoint_uri_path = var.entrypoint_uri_path
    mc_api_url          = var.mc_api_url
  }
}


resource "local_file" "prepared_lambda" {
  content  = data.template_file.lambda.rendered
  filename = "${path.module}/lambda/index.js"
}


module "lambda_at_edge" {
  version = "1.37.0"

  providers = {
    aws = aws.us-east-1
  }

  source  = "terraform-aws-modules/lambda/aws"
  publish = true

  lambda_at_edge     = true
  policy_json        = data.aws_iam_policy_document.lambda_s3_policy.json
  attach_policy_json = true

  attach_cloudwatch_logs_policy = true

  function_name = var.name
  description   = var.name
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  source_path = local_file.prepared_lambda.filename

  depends_on = [
    local_file.prepared_lambda

  ]
}
