data "aws_iam_policy_document" "lambda_s3_policy" {

  # Logging
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

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
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.cloudfront_identity.iam_arn
      ]
    }
  }
}
