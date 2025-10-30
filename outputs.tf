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
