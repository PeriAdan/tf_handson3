#create vpc with module
module "vpc" {
  source            = "git@github.com:PeriAdan/my_modules.git//vpc_module"
  custom_cidr       = var.cidr_block
  create_attach_igw = var.create_attach_igw
  custom_tag        = var.vpc_tag

}

module "subnets" {
  source            = "git@github.com:PeriAdan/my_modules.git//subnet"
  for_each          = var.subnet_for_each
  custom_vpc_id     = module.vpc.id
  custom_cidr       = each.value[0]
  custom_az         = each.value[1]
  custom_map        = each.value[2]
  custom_subnet_tag = each.key
}

module "natgtw" {
  source    = "git@github.com:PeriAdan/my_modules.git//natgw"
  subnet_id = module.subnets["public_1a"].id
  natgw_tag = var.natgw_tag

}

module "public_rtb" {
  source         = "git@github.com:PeriAdan/my_modules.git//rtb"
  vpc_id         = module.vpc.id
  gateway_id     = module.vpc.igw_id
  nat_gateway_id = null
  subnets        = [module.subnets["public_1a"].id, module.subnets["public_1b"].id]

}

module "private_rtb" {
  source         = "git@github.com:PeriAdan/my_modules.git//rtb"
  vpc_id         = module.vpc.id
  gateway_id     = null
  nat_gateway_id = module.natgtw.id
  subnets        = [module.subnets["private_1a"].id, module.subnets["private_1b"].id]

}

module "ec2_sg" {
  source      = "git@github.com:PeriAdan/my_modules.git//sg"
  name        = "${terraform.workspace}-sg"
  description = "${terraform.workspace}-sg"
  vpc_id      = module.vpc.id
  sg_tag      = "${terraform.workspace}-sg"
  sg_rules    = var.ec2_sg_rules
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.*-x86_64-gp2"]
  }
}

data "aws_key_pair" "mykey" {
  key_name = "TestPeri"
}

module "instances" {
  source = "git@github.com:PeriAdan/my_modules.git//ec2"

  for_each = {
    "${terraform.workspace}_instance_pub_1a" = module.subnets["public_1a"].id
    "${terraform.workspace}_instance_pub_1b" = module.subnets["public_1b"].id
  }
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.mykey.key_name
  vpc_security_group_ids = [module.ec2_sg.id]
  subnet_id              = each.value
  ins_tag                = each.key
  user_data              = file("${terraform.workspace}_userdata.sh")

}

module "alb_sg" {
  source      = "git@github.com:PeriAdan/my_modules.git//sg"
  name        = "${terraform.workspace}-alb_sg"
  description = "${terraform.workspace}-alb_sg"
  vpc_id      = module.vpc.id
  sg_tag      = "${terraform.workspace}-alb_sg"
  sg_rules    = var.alb_sg_rules
}

data "aws_route53_zone" "my_zone" {
  name         = "periadan.com"
  private_zone = "false"
}


#creat ssl cert

module "cert" {
  source                    = "git@github.com:PeriAdan/my_modules.git//acm"
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  cert_tag                  = "${terraform.workspace}_certificate"
  zone_id                   = data.aws_route53_zone.my_zone.id
}


module "tg" {
  source = "github.com/russgazin/b11-modules.git//tg_module"

  tg_name     = "${terraform.workspace}-tg"
  tg_port     = 80
  tg_protocol = "HTTP"
  tg_vpc_id   = module.vpc.id
  tg_tag      = "${terraform.workspace}_tg"
  instance_ids = [
    module.instances["${terraform.workspace}_instance_pub_1a"].id,
    module.instances["${terraform.workspace}_instance_pub_1b"].id,
  ]
}


module "alb" {
  source = "github.com/russgazin/b11-modules.git//alb_module"

  name               = "${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.id]
  subnets = [
    module.subnets["public_1a"].id,
    module.subnets["public_1b"].id
  ]

  alb_tag          = "${terraform.workspace}_alb"
  certificate_arn  = module.cert.arn
  target_group_arn = module.tg.tg_arn
}

module "cname" {
  source = "git@github.com:PeriAdan/my_modules.git//dns"

  zone_id = data.aws_route53_zone.my_zone.id
  name    = "${terraform.workspace}.periadan.com"
  type    = "CNAME"
  ttl     = 60
  records = [module.alb.dns_name]
}