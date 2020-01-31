# 20200131 start of TF learning
# use tags / owner to identify owner
# uses keep = "" to indicate not for deletion (no keep = "" means it will be deleted)

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Owner = "jstewart@hashicorp.com"
    Name = "JStewart"
  } 
}