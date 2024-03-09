cidr_block        = "10.0.1.0/24"
create_attach_igw = true
vpc_tag           = "prod_vpc"

subnet_for_each = {
  #key = value
  public_1a  = ["10.0.1.0/26", "us-east-1a", true]
  public_1b  = ["10.0.1.64/26", "us-east-1b", true]
  private_1a = ["10.0.1.128/26", "us-east-1a", false]
  private_1b = ["10.0.1.192/26", "us-east-1b", false]
}


natgw_tag = "prod_natgtw"

ec2_sg_rules = {
  SSH_from_www  = ["ingress", 22, 22, "TCP", "0.0.0.0/0"]
  http_from_www = ["ingress", 80, 80, "TCP", "0.0.0.0/0"]
  #http_from_www  = ["ingress", 80, 80, "tcp", "sg-09fa2e56e22b52acb"]
  traffic_to_www = ["egress", 0, 0, "-1", "0.0.0.0/0"]
}

instance_type = "t2.micro"

alb_sg_rules = {
  http_from_www  = ["ingress", 80, 80, "tcp", "0.0.0.0/0"]
  traffic_to_www = ["egress", 0, 0, "-1", "0.0.0.0/0"]
  https_from_www = ["ingress", 443, 443, "TCP", "0.0.0.0/0"]
}

domain_name               = "periadan.com"
subject_alternative_names = ["*.periadan.com"]