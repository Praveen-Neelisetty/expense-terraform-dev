module "db" {
  source         = "../../terraform-aws-securitygroup"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for DB MySQL Instances"
  common_tags    = var.common_tags
  sg_name        = "db"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value # By aws_ssm_parameter we are fetching vpc_id
}

module "backend" {
  source         = "../../terraform-aws-securitygroup"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for Backend Instances"
  common_tags    = var.common_tags
  sg_name        = "backend"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
}

module "frontend" {
  source         = "../../terraform-aws-securitygroup"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for Frontend Instances"
  common_tags    = var.common_tags
  sg_name        = "frontend"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
}

module "bastion" {
  source         = "../../terraform-aws-securitygroup"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for Bostion Instances"
  common_tags    = var.common_tags
  sg_name        = "bastion"
  vpc_id         = data.aws_ssm_parameter.vpc_id
}

module "ansible" {
  source         = "../../terraform-aws-securitygroup"
  project_name   = var.project_name
  environment    = var.environment
  sg_description = "SG for Ansible Instances"
  common_tags    = var.common_tags
  sg_name        = "ansible"
  vpc_id         = data.aws_ssm_parameter.vpc_id
}

# DB is accepting connections from backend,i-e from backend getting traffic to db
resource "aws_security_group_rule" "db_backend" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.backend.sg_id # source is where you are getting traffic from
  security_group_id        = module.db.sg_id
}

resource "aws_security_group_rule" "db_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id        = module.db.sg_id
}

resource "aws_security_group_rule" "backend_frontend" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.frontend.sg_id
  security_group_id        = module.backend.sg_id
}

resource "aws_security_group_rule" "backend_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id        = module.backend.sg_id
}

resource "aws_security_group_rule" "backend_ansible" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.ansible.sg_id
  security_group_id        = module.backend.sg_id
}


resource "aws_security_group_rule" "frontend_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend.sg_id
}

resource "aws_security_group_rule" "frontend_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion.sg_id # source is where you are getting traffic from
  security_group_id        = module.frontend.sg_id
}

resource "aws_security_group_rule" "frontend_ansible" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.ansible.sg_id # source is where you are getting traffic from
  security_group_id        = module.frontend.sg_id
}

resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

resource "aws_security_group_rule" "ansible_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.ansible.sg_id
}

