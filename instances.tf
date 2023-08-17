#this resource is used just to test provisioning the Vultr instances, 
#because Vultr cloud have a limit to create and destroy the resources
resource "aws_security_group" "allow_ssh" {
  name        = "DAS_allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "DAS_deployer_key"
  public_key = file("./id_rsa.pub") #here put the pub key for your machine access the servers instance
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# resource "aws_instance" "redis" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.deployer.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh.id]
#   user_data              = file("./install-redis.sh")
#   tags = {
#     Name = "DAS-redis"
#   }
# }

resource "aws_instance" "faas" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data              = file("./install-openfaas.sh")
  tags = {
    Name = "DAS-faas"
  }
}

# resource "aws_instance" "mongodb" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   key_name               = aws_key_pair.deployer.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh.id]
#   user_data              = file("./install-mongodb.sh")
#   tags = {
#     Name = "DAS-mongodb"
#   }
# }

# output "instance_ip_redis" {
#   value = aws_instance.redis.public_ip
# }

output "instance_ip_openfaas" {
  value = aws_instance.faas.public_ip
}

# output "instance_ip_mongodb" {
#   value = aws_instance.mongodb.public_ip
# }
