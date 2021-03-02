
locals {
  package_name = var.local_package != null ? basename(var.local_package) : var.package.key
}

resource "null_resource" "deploy" {
  triggers = {
    always_run = var.local_package != null ? filemd5(var.local_package) : "${var.package.bucket}/${var.package.key}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
        rm -rf .tmp-${local.package_name} && mkdir .tmp-${local.package_name}
        %{if var.local_package == null}
        aws s3 cp s3://${var.package.bucket}/${local.package_name} .tmp-${local.package_name}
        %{ else }
        cp ${var.local_package} .tmp-${local.package_name}
        %{ endif }
        cd .tmp-${local.package_name}/
        unzip ${local.package_name} && rm ${var.package.key}
        aws s3 sync --acl public-read . s3://${aws_s3_bucket.mc_app.bucket}/assets/${var.version_name}/
        cd .. && rm -rf .tmp-${var.package.key}
    EOT
  }
}
