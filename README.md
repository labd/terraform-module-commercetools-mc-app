# terraform-module-commercetools-mc-app

This module creates the resources needed within AWS to host your custom merchant center app


```hcl
module "merchant_center_app" {
  source = "https://github.com/labd/terraform-module-commercetools-mc-app.git"

  name = "my-merchant-center-app"

  external_api_url = "https://example.org/my-graphl-server"
  version_name     = var.component_version

  package = {
    bucket = local.lambda_s3_repository
    key    = local.mc_app_s3_key
  }

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```
