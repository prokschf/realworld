resource "aws_iam_role" "back_end_deploy_role" {
  name = "${var.project_name}-deploy-backend-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${var.openid_provider_arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "back_end_deploy_policy" {
  name = "default"
  role = aws_iam_role.back_end_deploy_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

output "backend-deploy-role-arn" {
  value       = aws_iam_role.back_end_deploy_role.arn
}
