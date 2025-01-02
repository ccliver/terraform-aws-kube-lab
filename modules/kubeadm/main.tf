data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  ami        = data.aws_ami.ubuntu.id
}

resource "aws_security_group" "endpoints" {
  name        = "${var.app_name}-endpoints"
  description = "VPC endpoint security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.public_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.public_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.public_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
}

#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "control_plane" {
  name        = "${var.app_name}-control-plane"
  description = "Control plane security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.api_allowed_cidrs)
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

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
    security_groups = [aws_security_group.nodes.id]
    self            = true
    cidr_blocks     = concat(var.api_allowed_cidrs)
  }

  ingress {
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.nodes.id]
  }

  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.nodes.id]
  }

  ingress {
    from_port       = 10259
    to_port         = 10259
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.nodes.id]
  }

  ingress {
    from_port       = 10257
    to_port         = 10257
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.nodes.id]
  }

  # For weavenet
  ingress {
    from_port       = 6783
    to_port         = 6783
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "nodes" {
  name        = "${var.app_name}-nodes"
  description = "Worker node security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "node_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "kubelet_api_1" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "kubelet_api_2" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "nodeport_services" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "weavenet_1" {
  type                     = "ingress"
  from_port                = 6783
  to_port                  = 6783
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.nodes.id
}

resource "aws_security_group_rule" "weavenet_2" {
  type              = "ingress"
  from_port         = 6783
  to_port           = 6783
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nodes.id
}

resource "aws_ssm_parameter" "join_string" {
  name        = "/${var.app_name}/kubeadm/join-string"
  description = "The command and token nodes use to join the cluster"
  type        = "SecureString"
  value       = "empty" # Populated by control plane via userdata

  tags = {
    Name = var.app_name
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "ca_cert" {
  name        = "/${var.app_name}/kubectl/certificate-authority-data"
  description = "kubectl CA cert"
  type        = "SecureString"
  value       = "empty" # Populated by control plane via userdata

  tags = {
    Name = var.app_name
  }
}

resource "aws_ssm_parameter" "client_cert" {
  name        = "/${var.app_name}/kubectl/client-certificate-data"
  description = "kubectl client cert"
  type        = "SecureString"
  value       = "empty" # Populated by control plane via userdata

  tags = {
    Name = var.app_name
  }
}

resource "aws_ssm_parameter" "client_key" {
  name        = "/${var.app_name}/kubectl/client-key-data"
  description = "kubectl client cert"
  type        = "SecureString"
  value       = "empty" # Populated by control plane via userdata

  tags = {
    Name = var.app_name
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
    resources = [
      aws_ssm_parameter.join_string.arn,
      aws_ssm_parameter.ca_cert.arn,
      aws_ssm_parameter.client_cert.arn,
      aws_ssm_parameter.client_key.arn
    ]
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
  name               = "${var.app_name}-control-plane"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name   = "control-plane"
    policy = data.aws_iam_policy_document.control_plane.json
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "control_plane" {
  name = "${var.app_name}-control-plane"
  role = aws_iam_role.control_plane.name
}

data "aws_iam_policy_document" "nodes" {
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

resource "aws_iam_role" "nodes" {
  name               = "${var.app_name}-nodes"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name   = "nodes"
    policy = data.aws_iam_policy_document.nodes.json
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "nodes" {
  name = "${var.app_name}-nodes"
  role = aws_iam_role.nodes.name
}

resource "aws_instance" "control_plane" {
  ami                    = local.ami
  instance_type          = var.control_plane_instance_type
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  subnet_id              = var.public_subnets[0]
  user_data = templatefile("${path.module}/control_plane_userdata.tpl", {
    hostname           = "${var.app_name}-control-plane",
    region             = local.region,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile        = aws_iam_instance_profile.control_plane.id
  associate_public_ip_address = true
  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.app_name}-control-plane"
  }
}

resource "aws_instance" "nodes" {
  count = var.node_instances

  ami                    = local.ami
  instance_type          = var.node_instance_type
  vpc_security_group_ids = [aws_security_group.nodes.id]
  subnet_id              = var.private_subnets[count.index]
  user_data = templatefile("${path.module}/node_userdata.tpl", {
    region             = local.region,
    kubernetes_version = var.kubernetes_version
  })
  iam_instance_profile        = aws_iam_instance_profile.nodes.id
  associate_public_ip_address = false
  root_block_device {
    delete_on_termination = true
    encrypted             = true
  }
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${var.app_name}-node-${count.index + 1}"
  }
}

resource "aws_s3_bucket" "etcd_backups" {
  count = var.create_etcd_backups_bucket ? 1 : 0

  bucket = "etcd-backups-${uuid()}"
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
