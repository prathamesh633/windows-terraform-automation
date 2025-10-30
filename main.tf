provider "aws" {
  region = var.aws_region
}

# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# 2. Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# 3. Create an internet gateway and route table for Internet access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

# 4. Security group allowing RDP and HTTP
resource "aws_security_group" "windows" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for Windows instance"
  vpc_id      = aws_vpc.main.id
  
  tags = {
    Name = "${var.name_prefix}-sg"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# 5. Generate password for Windows instance
resource "aws_ssm_parameter" "windows_password" {
  name        = "/ec2/windows/password"
  type        = "SecureString"
  value       = random_password.windows.result
  description = "Password for the Windows EC2 instance"
  overwrite   = true  # This allows updating the parameter if it already exists
}

resource "random_password" "windows" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 6. Windows EC2 Instance with user creation via user_data
resource "aws_instance" "windows" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.windows.id]
  key_name               = "office-key"
  get_password_data      = true

  user_data = <<-EOF
    <powershell>
    # Create a new standard user
    $username = "user1"
    $password = "${var.windows_user_password}"
    
    # Create the user
    net user $username $password /add /y
    
    # Add user to Users group (standard user)
    net localgroup "Users" $username /add
    
    # Optional: Set password to never expire
    WMIC UserAccount WHERE Name='$username' SET PasswordExpires=FALSE
    
    # Enable RDP (if not already enabled)
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Allow RDP through firewall
    netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
    
    Write-Host "User $username created successfully"
    </powershell>
    <persist>true</persist>
  EOF

  tags = {
    Name = "${var.name_prefix}-ec2"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}
