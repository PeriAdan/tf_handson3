terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "terraformperi"
    key    = "terraform-hd"
  }
}