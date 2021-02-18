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
