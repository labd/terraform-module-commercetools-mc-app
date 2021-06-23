
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  package_name = var.local_package != null ? basename(var.local_package) : var.package.key
  assume_role  = format("arn:aws:iam::%s", join(":role/", regex("arn:aws:sts::([^:]+):assumed-role/([^/]+)", data.aws_caller_identity.current.arn)))
}


resource "null_resource" "deploy" {
  triggers = {
    always_run = var.local_package != null ? filemd5(var.local_package) : "${var.package.bucket}/${var.package.key}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
CREDENTIALS=(`aws sts assume-role \
  --role-arn ${local.assume_role} \
  --role-session-name "terraform-deploy" \
  --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]" \
  --output text`)

if [ $? -eq 0 ]
then
  unset AWS_PROFILE
  unset AWS_SECURITY_TOKEN
  export AWS_DEFAULT_REGION=${data.aws_region.current.name}
  export AWS_ACCESS_KEY_ID="$${CREDENTIALS[0]}"
  export AWS_SECRET_ACCESS_KEY="$${CREDENTIALS[1]}"
  export AWS_SESSION_TOKEN="$${CREDENTIALS[2]}"
fi
set -e

rm -rf .tmp-${local.package_name} && mkdir .tmp-${local.package_name}
%{if var.local_package == null}
aws s3 cp s3://${var.package.bucket}/${local.package_name} .tmp-${local.package_name}
%{else}
cp ${var.local_package} .tmp-${local.package_name}
%{endif}

cd .tmp-${local.package_name}/
unzip ${local.package_name} && rm ${var.package.key}
aws s3 sync . s3://${aws_s3_bucket.mc_app.bucket}/assets/${var.version_name}/
cd .. && rm -rf .tmp-${var.package.key}
EOF
  }
}

