provider "aws" {
  region = "us-east-2"
}

module "kube-lab" {
  source = "../.."

  ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDX6ENxXBXk7gLRuZmJEuS9bJnEdv6ZWWhZcJL4zP7X6j6Gwpo0bFQPkK9tiHa5rS62JMhMe58z0JfbFr6u5UF1fm8pahN+qMNb/8WSaz8iILdTQVGKWWRAUuE1n7t6rBbKF3SXTE0i7b99pdDZyb+X8rEgsgzpKxfqt1H5oE2wOeNQBySsW7WkrHpl1OZNe3OI+KhybtmAlrvs2Te/2rzG2G9wp3WpgG32f3n9gzn2yT4MXTbXpBaBwmxB87gONWaLZULKv4bUelR/8r5XPVoC8yaYR1A7CwfBeMtt7Dsqy2NtCD0HYJwzUgCiJy7ONitNAVXdaYr4JsWtZE1U1cD/Ge/W/58h2eA9UjwUGfrnrCrrmFp0/0dhXfAlQDrbObhxLXFUTMGOwU8s2XuXaggSkr66UIPgGcpnjI7B+5UASFu9hG0QfGReiWMvg2vmZ/dlh1h6AsvQYhF6r13ouqDYSJwPN3ICmtDjXBbShUYvDN1Gvpl/EUzvXs918GrAVvM="
  ssh_allowed_cidrs = ["71.214.161.93/32"]
}
