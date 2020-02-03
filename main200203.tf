# 20200131 start of TF learning
# use tags name & owner to identify owner:
#    Owner = "jstewart@hashicorp.com"
#    Name = "JStewart"
# use keep = "" to indicate not for deletion (not inserting keep = "" means it will be deleted)

provider "aws" {
  region = "us-east-2"
}

# create an instance using an AMI
resource "aws_instance" "js-example" {
	ami			= "ami-0c55b159cbfafe1f0"
	instance_type		= "t2.micro"
  # use reference of security group id to tell instance which SG to use
  vpc_security_group_ids = [aws_security_group.js-sg.id] 

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
  name = "js-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# book page 58 - variables
#variable "object_example_with_error" {
#     description = "An example of a structural type in Terraform with an error"
#     type = object({
#       name = string
#       age = number
#       tags = list(string)
#       enabled = bool
#     })
    
#     default = {
#       name = "value1"
#       age = 42
#       tags = ["a", "b", "c"]
#       enabled = "invalid"
#     }
#   }
  
# Setting a variable for port number - will be prompted for the port number when you apply
variable "server_port" {
  description = "The port the server will use for http requests"
  type = number
}


