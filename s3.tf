resource "aws_s3_bucket" "mc_app" {
  bucket = var.name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
