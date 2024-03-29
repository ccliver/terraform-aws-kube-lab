data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-202*"]
  }

  owners = ["099720109477"] # Canonical
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name    = "${var.resource_name}-vpc"
  cidr    = var.vpc_cidr
  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2]
  ]
  public_subnets = var.public_subnet_cidrs

  vpc_tags = {
    Name = "${var.resource_name}-vpc"
  }
}

resource "aws_security_group" "control_plane" {
  name   = "${var.resource_name}-control-plane"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.workers.id]
    self            = true
    cidr_blocks     = concat(var.ssh_allowed_cidrs, var.api_allowed_cidrs)
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_allowed_cidrs
  security_group_id = aws_security_group.workers.id
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

resource "aws_key_pair" "cluster" {
  key_name   = var.resource_name
  public_key = var.ssh_public_key
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
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"]
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
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ssm"]
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
}

resource "aws_iam_instance_profile" "workers" {
  name = "${var.resource_name}-workers"
  role = aws_iam_role.workers.name
}

resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.control_plane_instance_type
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = aws_key_pair.cluster.key_name
  user_data = templatefile("${path.module}/control_plane_userdata.tpl", {
    hostname           = "${var.resource_name}-control-plane",
    region             = data.aws_region.current.name,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile = aws_iam_instance_profile.control_plane.id

  tags = {
    Name = "${var.resource_name}-control-plane"
  }
}

resource "aws_instance" "workers" {
  count                  = var.worker_instances
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [aws_security_group.workers.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = aws_key_pair.cluster.key_name
  user_data = templatefile("${path.module}/worker_userdata.tpl", {
    hostname           = "${var.resource_name}-worker-${count.index + 1}"
    region             = data.aws_region.current.name,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile = aws_iam_instance_profile.workers.id

  tags = {
    Name = "${var.resource_name}-worker-${count.index + 1}"
  }
}

resource "random_string" "random" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  length  = 6
  special = false
  lower   = true
  upper   = false
}

resource "aws_s3_bucket" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = "etcd-backups-${random_string.random[0].result}"
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
