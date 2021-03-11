terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.31.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "build" {
  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  key_name = "tf-key"
  associate_public_ip_address = true

tags = {
    Name = "build_server"
  }

 connection {
    type        = "ssh"
    host        = aws_instance.build.public_ip
    user        = "ubuntu"
    port        = 22
    private_key = "${file("/home/ubuntu/connect_key/tf-key.pem")}"
    agent       = false
  }

 provisioner "file" {
    source      = "~/.docker/config.json"
    destination = "/home/ubuntu/config.json"
  }

  provisioner "remote-exec" {
    inline = [
      #"sudo su",
      "sudo apt update",
      "sudo apt install docker.io -y",
      "cd /home/ubuntu",
      "git clone https://github.com/henre1989/Dockerfile_java_app.git",
      "cd Dockerfile_java_app",
      #"sudo docker build -t henre1989/myapp .",
      "sudo mkdir ~/.docker",
      "sudo chmod -R 0700 ~/.docker",
      "sudo cp /home/ubuntu/config.json ~/.docker",
      #"sudo docker push henre1989/myapp",
    ]
  }


}
resource "aws_instance" "Run_app" {
  ami           = "ami-08962a4068733a2b6"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.run_app.id]
  key_name = "tf-key"
  depends_on = [aws_instance.build]
  user_data = <<EOF
#!/bin/bash
apt update
apt install docker.io -y
docker run -d -p 8080:8080 henre1989/myapp
EOF
tags = {
    Name = "run_app_server"
  }
}

resource "aws_security_group" "run_app" {
  name        = "Build Server Security Group"
  description = "My Build Server Security Group"


  ingress {
    description = "tomcat ports"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }

}
