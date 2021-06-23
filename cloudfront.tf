resource "aws_cloudfront_origin_access_identity" "cloudfront_identity" {
  comment = "MC APP CloudFront"
}

resource "aws_cloudfront_distribution" "mc_app" {
  enabled = true

  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  wait_for_deployment = false

  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-bucket"

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = module.lambda_at_edge.this_lambda_function_qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = module.lambda_at_edge.this_lambda_function_qualified_arn
    }

    forwarded_values {
      query_string = true

      headers = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "X-MC-API-Cloud-Identifier",
        "Origin",
      ]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    max_ttl                = 0
    default_ttl            = 0
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name = aws_s3_bucket.mc_app.bucket_domain_name
    origin_id   = "s3-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront_identity.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
