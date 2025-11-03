output "windows_instance_ip" {
  description = "Public IP address of the Windows instance"
  value       = aws_instance.windows.public_ip
}

output "rdp_connection_command" {
  description = "Command to connect to the Windows instance via RDP"
  value       = "mstsc /v:${aws_instance.windows.public_ip}"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.windows.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.windows.public_ip
}

# Output the Windows password (if get_password_data is true)
# output "windows_password" {
#   description = "Windows administrator password"
#   value       = aws_instance.windows.password_data
#   sensitive   = true
# }
