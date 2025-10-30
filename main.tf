provider "aws" {
  region = "ap-south-1"
}

# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# 2. Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
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
  name        = "allow_rdp_http"
  vpc_id      = aws_vpc.main.id

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
  name  = "/ec2/windows/password"
  type  = "SecureString"
  value = random_password.windows.result
}

resource "random_password" "windows" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

# 6. Windows EC2 Instance with user creation via user_data
resource "aws_instance" "windows" {
  ami                         = "ami-089e0600a8bb6d176" # Windows Server 2022 Base 
  instance_type               = "t3.medium" # Windows typically needs more resources
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.windows.id]
  associate_public_ip_address = true

  # Use the generated password
  get_password_data = true

  user_data = <<-EOF
    <powershell>
    # Create a new standard user
    $username = "user1"
    $password = "${random_password.windows.result}"
    
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
    Name = "Windows-Terraform-EC2"
  }
}

# 7. Output the connection information
output "windows_instance_ip" {
  value = aws_instance.windows.public_ip
}

output "rdp_connection_command" {
  value = "mstsc /v:${aws_instance.windows.public_ip}"
}

output "administrator_password" {
  value     = aws_instance.windows.password_data
  sensitive = true
}

output "user1_password" {
  value     = random_password.windows.result
  sensitive = true
}
