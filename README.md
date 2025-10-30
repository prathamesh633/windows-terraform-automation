# Terraform: EC2 + user1 creation

What this does:
- Creates an EC2 instance (Amazon Linux 2).
- Creates a Linux user `user1` on instance, sets home directory permissions to `0775`.
- Copies existing default user's `authorized_keys` into `user1` so you can SSH as `user1`.
- Adds passwordless sudo for `user1` (you can remove this from `main.tf`'s user_data if you don't want it).

Prerequisites:
- Terraform installed (recommended >= 1.0).
- AWS credentials configured (environment variables or ~/.aws/credentials).
- A public SSH key string (e.g., contents of `~/.ssh/id_rsa.pub`).

Quick start:
1. Save your SSH public key into a tfvars file (or pass as var on CLI). Example `terraform.tfvars`:
   public_key = "ssh-rsa AAAA... your-key-comment"
   key_name   = "my-key-name"
   allowed_cidr = "203.0.113.0/32" # restrict SSH access to your IP

2. Initialize and apply:
   terraform init
   terraform apply

   Confirm the apply. After apply completes, Terraform outputs the instance public IP.

3. SSH:
   - By default you will SSH to the instance user (ec2-user on Amazon Linux 2) using the private key that matches the public key you provided.
   - If you want to SSH as user1 you can run:
     ssh -i /path/to/your/private_key user1@<instance_public_ip>

Security notes:
- The default allowed_cidr is 0.0.0.0/0 (open to the world) for SSH. Change `allowed_cidr` to your IP or CIDR block.
- Storing private keys or sensitive values in Terraform state is something to be mindful of. Don't add private keys to variables.
- The instance grants passwordless sudo to user1. Remove the sudoers lines in `main.tf` if you do not want that.

Cleanup:
- To destroy all resources:
  terraform destroy
