###
### SSH
###

# Generate an SSH key pair
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the public key to a local file
resource "local_file" "ssh_public_key" {
  filename = "${path.module}/.key.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Save the private key to a local file
resource "local_sensitive_file" "ssh_private_key" {
  filename = "${path.module}/.key.private"
  content = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}
