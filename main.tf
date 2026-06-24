provider "aws" {
  access_key = var.v-access-key
  secret_key = var.v-secret-key
  region     = var.v-region
}

resource "aws_vpc" "do1-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "DO1-VPC"
  }
}

resource "aws_internet_gateway" "do1-igw" {
  vpc_id = aws_vpc.do1-vpc.id
  tags = {
    Name = "DO1-IGW"
  }
}

resource "aws_route_table" "do1-prt" {
  vpc_id = aws_vpc.do1-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.do1-igw.id
  }
  tags = {
    Name = "DO1-PUBLIC_RT"
  }
}

resource "aws_subnet" "do1-snet" {
  count                   = var.v-count
  vpc_id                  = aws_vpc.do1-vpc.id
  cidr_block              = var.do1-cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.do1-avz.names[count.index]
  tags = {
    Name = "DO1-SUB-NET-${count.index + 1}"
  }
}


resource "aws_route_table_association" "do1-prt-assoc" {
  count          = var.v-count
  subnet_id      = aws_subnet.do1-snet.*.id[count.index]
  route_table_id = aws_route_table.do1-prt.id
}

resource "aws_security_group" "do1-pub-sg" {
  name        = "do1-pub-sg"
  description = "DO1 Public SG"
  vpc_id      = aws_vpc.do1-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Ping (ICMP)"
    from_port   = -1 # -1 означава всички видове ICMP съобщения (включително echo-request)
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] # Позволява ping от целия свят
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "do1-server" {
  count                  = var.v-count
  ami                    = var.v-ami-image
  instance_type          = var.v-instance-type
  key_name               = var.v-instance-key
  vpc_security_group_ids = [aws_security_group.do1-pub-sg.id]
  subnet_id              = aws_subnet.do1-snet.*.id[count.index]
  tags = {
    Name = "do1-server-${count.index + 1}"
  }
  # 1. Първо качваш скрипта за инсталация 
  provisioner "file" {
    source      = "./provision.sh"
    destination = "/tmp/provision.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("terraform-key.pem")
      host        = self.public_ip
    }
  }

  # 2. Създаваш и качваш index.html с динамична инфо от Terraform
  provisioner "file" {
    # Използваме content вместо source, за да пишем динамичен текст директно тук
    content     = <<-EOF
      <!DOCTYPE html>
      <html>
      <head>
          <title>Managed by Terraform</title>
          <style>
              body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f9; }
              .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
              h1 { color: #4B0082; }
          </style>
      </head>
      <body>
          <div class="card">
              <h1>Hello from AWS EC2!</h1>
              <p><strong>Hostname:</strong> ${self.tags.Name}</p>
              <p><strong>Public IP:</strong> ${self.public_ip}</p>
              <p><strong>Environment (Workspace):</strong> ${terraform.workspace}</p>
              <p><strong>Provisioned on:</strong> 2026-06-24</p>
          </div>
      </body>
      </html>
    EOF
    destination = "/tmp/index.html"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("terraform-key.pem")
      host        = self.public_ip
    }
  }

  # 3. Изпълняваш скрипта и преместваш index.html на правилното място
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/provision.sh",
      "/tmp/provision.sh",
      # Местим готовия html файл в директорията на уеб сървъра (Nginx/Apache) с права на root:
      "sudo mv /tmp/index.html /var/www/html/index.html"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("terraform-key.pem")
      host        = self.public_ip
    }
  }
}




