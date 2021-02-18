resource "null_resource" "deploy" {
  triggers = {
    always_run = "${var.package.bucket}/${var.package.key}-x"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
        rm -rf .tmp-${var.package.key} && mkdir .tmp-${var.package.key}
        aws s3 cp s3://${var.package.bucket}/${var.package.key} .tmp-${var.package.key}
        cd .tmp-${var.package.key}/
        unzip ${var.package.key} && rm ${var.package.key}
        aws s3 sync --acl public-read . s3://${aws_s3_bucket.mc_app.bucket}/assets/${var.version_name}/
        cd .. && rm -rf .tmp-${var.package.key}
    EOT
  }
}
