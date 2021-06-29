data "aws_iam_policy_document" "lambda_s3_policy" {

  statement {
    sid       = "AllowS3PutInvoices"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.mc_app.arn}/*"]
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl"
    ]
  }
}

data "aws_iam_policy_document" "bucket_policy" {

  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.name}",
      "arn:aws:s3:::${var.name}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.cloudfront_identity.iam_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = toset(var.upload_role_arns)

    content {
      actions = [
        "s3:*",
      ]

      resources = [
        "arn:aws:s3:::${var.name}",
        "arn:aws:s3:::${var.name}/*",
      ]

      principals {
        type        = "AWS"
        identifiers = [statement.key]
      }
    }
  }
}
