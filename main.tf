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
  # アクセス権限
  acl    = "public-read"
  # 許可するオリジン、メソッドを追加
  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_bucket" "alb_log" {
  bucket = "alb-log-progmatic-terraform"
  # 180日経ったものは自動削除
  lifecycle_rule {
    enabled = true
    expiration {
      days = "180"
    }
  }
}

# パケットポリシー　ALBなど書き込みを行う時に必要
resource "aws_s3_bucket_policy" "aws_log" {
  bucket = aws_s3_bucket.alb_log.id 
  policy = data.aws_iam_policy_document.aws_log.json
}

data "aws_iam_policy_document" "aws_log" {
  statement {
    effect = "Allow"
    actions = ["s3.PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type = "AWS"
      identifiers = ["644885757165"]
    }
  }
}

## S3の削除
# resource "aws_s3_bucket" "force_destroy" {
#   bucket = "force-destroy-progmatic-terraform"
#   force_destroy = true
# }

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true 
  enable_dns_hostnames = true 
  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.0.0/24"
   # 自動的なパブリックIPアドレスの割当
  map_public_ip_on_launch = true 
  availability_zone = "ap-northeast-1a"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  # VPC以外への通信をデータを流す
  gateway_id = aws_internet_gateway.public.id 
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" { 
  subnet_id = aws_subnet.public.id 
  route_table_id = aws_route_table.public.id
}