data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-202*"]
  }

  owners = ["099720109477"] # Canonical
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  azs        = data.aws_availability_zones.available.names
  ami        = data.aws_ami.ubuntu.id
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name    = "${var.resource_name}-vpc"
  cidr    = var.vpc_cidr
  azs = [
    local.azs[0],
    local.azs[1],
    local.azs[2]
  ]
  public_subnets             = var.public_subnet_cidrs
  private_subnets            = var.private_subnet_cidrs
  manage_default_network_acl = false

  vpc_tags = {
    Name = "${var.resource_name}-vpc"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.public_subnets
  security_group_ids  = [aws_security_group.workers.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.public_subnets
  security_group_ids  = [aws_security_group.workers.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.public_subnets
  security_group_ids  = [aws_security_group.workers.id]
}

resource "aws_security_group" "control_plane" {
  name   = "${var.resource_name}-control-plane"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.workers.id]
    self            = true
    cidr_blocks     = concat(var.api_allowed_cidrs)
  }

  ingress {
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.workers.id]
  }

  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.workers.id]
  }

  ingress {
    from_port       = 10259
    to_port         = 10259
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.workers.id]
  }

  ingress {
    from_port       = 10257
    to_port         = 10257
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.workers.id]
  }

  # For weavenet
  ingress {
    from_port       = 6783
    to_port         = 6783
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.workers.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "workers" {
  name   = "${var.resource_name}-workers"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "kubelet_api_1" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.workers.id
}

resource "aws_security_group_rule" "kubelet_api_2" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "nodeport_services" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "weavenet_1" {
  type                     = "ingress"
  from_port                = 6783
  to_port                  = 6783
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.workers.id
}

resource "aws_security_group_rule" "weavenet_2" {
  type              = "ingress"
  from_port         = 6783
  to_port           = 6783
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.workers.id
}

resource "aws_ssm_parameter" "join_string" {
  name        = "/${var.resource_name}/kubeadm/join-string"
  description = "The command and token workers use to join the cluster"
  type        = "SecureString"
  value       = "empty" # Populated by control plane via userdata

  tags = {
    Name = var.resource_name
  }

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "control_plane" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [aws_ssm_parameter.join_string.arn]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "ssm:Decrypt"
    ]
    resources = ["arn:aws:kms:${local.region}:${local.account_id}:alias/aws/ssm"]
  }
}

resource "aws_iam_role" "control_plane" {
  name               = "${var.resource_name}-control-plane"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name   = "control-plane"
    policy = data.aws_iam_policy_document.control_plane.json
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "control_plane" {
  name = "${var.resource_name}-control-plane"
  role = aws_iam_role.control_plane.name
}

data "aws_iam_policy_document" "workers" {
  statement {
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]
    resources = [aws_ssm_parameter.join_string.arn]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "ssm:Decrypt"
    ]
    resources = ["arn:aws:kms:${local.region}:${local.account_id}:alias/aws/ssm"]
  }
}

resource "aws_iam_role" "workers" {
  name               = "${var.resource_name}-workers"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name   = "workers"
    policy = data.aws_iam_policy_document.workers.json
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "workers" {
  name = "${var.resource_name}-workers"
  role = aws_iam_role.workers.name
}

resource "aws_instance" "control_plane" {
  ami                    = local.ami
  instance_type          = var.control_plane_instance_type
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = templatefile("${path.module}/control_plane_userdata.tpl", {
    hostname           = "${var.resource_name}-control-plane",
    region             = local.region,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile        = aws_iam_instance_profile.control_plane.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.resource_name}-control-plane"
  }
}

resource "aws_instance" "workers" {
  count                  = var.worker_instances
  ami                    = local.ami
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [aws_security_group.workers.id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = templatefile("${path.module}/worker_userdata.tpl", {
    hostname           = "${var.resource_name}-worker-${count.index + 1}"
    region             = local.region,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile        = aws_iam_instance_profile.workers.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.resource_name}-worker-${count.index + 1}"
  }
}

resource "aws_s3_bucket" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = "etcd-backups-${uuid()}"
}

resource "aws_s3_bucket_acl" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = aws_s3_bucket.etcd_backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
