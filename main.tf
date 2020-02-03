# 20200131 start of TF learning
# use tags / owner to identify owner
# uses keep = "" to indicate not for deletion (no keep = "" means it will be deleted)

provider "aws" {
  region = "us-east-2"
}

# create an instance using an AMI
resource "aws_instance" "js-instance" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # create an index.html file when the server starts up. nohup is a builtin Ubuntu http service  
  user_data = <<-EOF
          #!/bin/bash
          echo "Hello James" > index.html
          nohup busybox httpd -f -p 8080 &
          EOF
#  always set owner for any Hashi instance
  tags = {
    Owner = "jstewart@hashicorp.com"
    Name = "JStewart"
  } 
}
  
# create a security group. AWS by default does not allow traffic on or out of an instance
resource "aws_security_group" "js-sg" {
  name = "js-sec-group"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  