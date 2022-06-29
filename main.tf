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
  source             = "terraform-aws-modules/vpc/aws"
  version            = "3.14.2"
  name               = "${var.resource_name}-vpc"
  cidr               = "10.0.0.0/16"
  azs                = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true

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
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    security_groups = [aws_security_group.workers.id]
    self      = true
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 10259
    to_port   = 10259
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 10257
    to_port   = 10257
    protocol  = "tcp"
    self      = true
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
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.ssh_allowed_cidrs
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "kubelet_api_1" {
  type = "ingress"
  from_port = 10250
  to_port   = 10250
  protocol  = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "kubelet_api_2" {
  type = "ingress"
  from_port = 10250
  to_port   = 10250
  protocol  = "tcp"
  self      = true
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "nodeport_services_1" {
  type = "ingress"
  from_port = 30000
  to_port   = 32767
  protocol  = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id = aws_security_group.workers.id
}

resource "aws_security_group_rule" "nodeport_services_2" {
  type = "ingress"
  from_port = 30000
  to_port   = 32767
  protocol  = "tcp"
  self      = true
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
  value       = "empty" // Populated by control plane via userdata

  tags = {
    Name = var.resource_name
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
    actions   = [
      "ssm:GetParameter",
      "ssm:PutParameter"
    ]
    resources = [aws_ssm_parameter.join_string.arn]
  }

  statement {
    actions   = [
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
    actions   = [
      "ssm:DescribeParameters",
      "ssm:GetParameter"
    ]
    resources = [aws_ssm_parameter.join_string.arn]
  }

  statement {
    actions   = [
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
  user_data              = file("${path.module}/control_plane_userdata.sh")
  iam_instance_profile   = aws_iam_instance_profile.control_plane.id

  tags = {
    Name = "${var.resource_name}-control-plane"
  }
}

resource "aws_instance" "workers" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  vpc_security_group_ids = [aws_security_group.workers.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = aws_key_pair.cluster.key_name
  user_data              = file("${path.module}/worker_userdata.sh")
  iam_instance_profile   = aws_iam_instance_profile.workers.id

  tags = {
    Name = "${var.resource_name}-worker-${count.index + 1}"
  }
}
