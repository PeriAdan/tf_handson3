cidr_block        = "10.0.0.0/24"
create_attach_igw = true
vpc_tag           = "dev_vpc"

subnet_for_each = {
  #key = value
  public_1a  = ["10.0.0.0/26", "us-east-1a", true]
  public_1b  = ["10.0.0.64/26", "us-east-1b", true]
  private_1a = ["10.0.0.128/26", "us-east-1a", false]
  private_1b = ["10.0.0.192/26", "us-east-1b", false]
}


natgw_tag = "dev_natgtw"

ec2_sg_rules = {
  SSH_from_www   = ["ingress", 22, 22, "TCP", "0.0.0.0/0"]
  http_from_www  = ["ingress", 80, 80, "tcp", "sg-08e982c703eb8ae6f"]
  traffic_to_www = ["egress", 0, 0, "-1", "0.0.0.0/0"]
}

instance_type = "t2.micro"

alb_sg_rules = {
  http_from_www  = ["ingress", 80, 80, "tcp", "0.0.0.0/0"]
  traffic_to_www = ["egress", 0, 0, "-1", "0.0.0.0/0"]
  https_from_www = ["ingress", 443, 443, "TCP", "0.0.0.0/0"]
}

rds_sg_rules = {
  mysql_from_www  = ["ingress", 3306, 3306, "TCP", "0.0.0.0/0"]
  outbound_to_www = ["egress", 0, 0, "-1", "0.0.0.0/0"]
}


domain_name               = "periadan.com"
subject_alternative_names = ["*.periadan.com"]