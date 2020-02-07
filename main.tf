# 20200131 start of TF learning
# use tags name & owner to identify owner:
#    Owner = "jstewart@hashicorp.com"
#    Name = "JStewart"
# use keep = "" to indicate not for deletion (not inserting keep = "" means it will be deleted)

provider "aws" {
  region = "eu-west-2"
}

# define aws default VPC
data "aws_vpc" "js-default" {
  default = true
}

# pull subnet ID's from default VPC
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.js-default.id  
}

# create an instance using an AMI
# resource "aws_instance" "js-instance" {
# 	ami			= "ami-07dc734dc14746eab"
# 	instance_type		= "t2.micro"
#   # use reference of security group id to tell instance which SG to use
#   vpc_security_group_ids = [aws_security_group.js-sg.id] 

#   # create an index.html file when the server starts up. nohup is a builtin Ubuntu http service  
#   user_data = <<-EOF
#           #!/bin/bash
#           echo "Hello James" > index.html
#           nohup busybox httpd -f -p ${var.server_port} &
#           EOF

# #  always set owner for any Hashi instance
#   tags = {
#     Owner = "jstewart@hashicorp.com"
#     Name = "JStewart"
#   } 
# }
  
# create a security group. AWS by default does not allow traffic on or out of an instance
resource "aws_security_group" "js-sg" {
  name = "js-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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
  default = 8080
}

# set an ouptput variable to get the public IP adress of the server
# output "Public_IP" {
#   value = aws_instance.js-instance.public_ip
#   description = "The public IP address of the server"
# }

resource "aws_launch_configuration" "js-lc" {
  name_prefix = "jstewart-"
  image_id = "ami-07dc734dc14746eab"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.js-sg.id]

  user_data = <<-EOF
          #!/bin/bash
          echo "Hello Sir James" > index.html
          nohup busybox httpd -f -p ${var.server_port} &
          EOF

# Required when using a launch configuration with an ASG.
# https://terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "js-asg" {
  name_prefix = "JStewart-"
  launch_configuration = aws_launch_configuration.js-lc.name
# Define subnet ID's - page 64  
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  desired_capacity = 3


# Define target group that the ASG will use
  target_group_arns = [aws_lb_target_group.js_alb_tg.arn]
  health_check_type = "ELB"
  
  max_size = "10"
  min_size = "2"

  tag {
    key = "Name"
    value = "JStewart-ASG"
    propagate_at_launch = true
  }
  tag {
    key = "Owner"
    value = "jstewart@hashicorp.com"
    propagate_at_launch = true
  }
}

resource "aws_lb" "js_alb" {
  name_prefix = "js-"
  load_balancer_type = "application"
#  security_groups = "Optional"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.js_alb_sg.id]
  
  tags = {
    Owner = "jstewart@hashicorp.com"
    Name = "JStewart"
  } 
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.js_alb.arn
  port = "80"
  protocol = "HTTP"

#by default return a 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Dude! Where's my page?"
      status_code = "404"
    }
  }
}

resource "aws_lb_listener_rule" "listen_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority = "100"
  
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.js_alb_tg.arn
  }
# https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html#path_pattern  
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_security_group" "js_alb_sg" {
  name = "js_alb_security_group"
  description = "sg description"
  
# Allow incoming HTTP requests
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#Allow all outbound requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "js_alb_tg" {
  name = "js-target-group"
  # name_prefix = "js-"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.js-default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
    
  }
}  

# set an ouptput variable to get the public IP adress of the server
output "alb_dns_name" {
  value = aws_lb.js_alb.dns_name
  description = "The Load Balancers DNS name"
}


  # tags {
  #   Owner = "jstewart@hashicorp.com"
  # }