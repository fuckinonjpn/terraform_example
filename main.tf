# IAMポリシーの内容
data "aws_iam_policy_document" "allow_describe_regions" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeRegions"]
    resources = ["*"]
  }
}

# IAMポリシーのリソースを作成
# resource "aws_iam_policy" "example" {
#   name   = "example"
#   policy = data.aws_iam_policy_document.allow_describe_regions.json
# }

# # IAMロール（信頼）の内容を記載　EC2にのみ関連付けすることができる
# data "aws_iam_policy_document" "ec2_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

# # IAMロールを作成
# resource "aws_iam_role" "example" {
#   name               = "example"
#   assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
# }

# # IAMポリシーとIAMロールを紐付けて有効にする
# resource "aws_iam_role_policy_attachment" "example" {
#   role       = aws_iam_role.example.name
#   policy_arn = aws_iam_policy.example.arn
# }



module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}

resource "aws_s3_bucket" "private" {
  # 全世界で一意性制約
  bucket = "private-promatic-terraform"
  # 以下は追加のデメリット無し
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# S3のパブリックアクセス防止
resource "aws_s3_bucket_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform"
  acl    = "public-read"
}
