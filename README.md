# 🚀 Deploying n8n to AWS EC2 with Docker Compose

This repository provides a quick and secure way to deploy [n8n](https://n8n.io/), an open-source workflow automation tool, on an AWS EC2 instance using Docker and Docker Compose.

n8n allows you to connect various services and automate workflows with a visual interface. This setup is ideal for individuals learning how n8n works or small personal projects. It is not meant to be a scalable production solution.

## ⚠️ IMPORTANT DISCLAIMER

**THIS IS FOR EDUCATIONAL PURPOSES ONLY**

This guide demonstrates a basic setup for learning and testing purposes. It is **NOT** intended for production use. For production deployments:

- **Contact n8n Directly**: For enterprise-grade deployments, contact [n8n's team](https://n8n.io/contact) directly
- **Consider n8n Cloud**: Use [n8n's official cloud offering](https://n8n.io/cloud) for a fully managed solution
- **Professional Support**: For custom deployments, consider reaching out to certified n8n partners or consultants

### Why This Disclaimer Matters

- **Security**: Production environments require additional security measures
- **Reliability**: Business-critical workflows need proper monitoring and redundancy
- **Compliance**: Your organization may have specific regulatory requirements
- **Support**: Production deployments need proper support and maintenance plans
- **Scalability**: Business needs may require more robust infrastructure

### When to Use This Guide

✅ Learning how n8n works
✅ Testing and development
✅ Personal projects
✅ Proof of concept

### When NOT to Use This Guide

❌ Business-critical workflows
❌ Processing sensitive data
❌ High-availability requirements
❌ Production environments
❌ Enterprise deployments

## 📁 Files Included

- `docker-compose.yaml` – defines the n8n service and persistent volume
- `.env.example` – stores environment-specific credentials and configuration
- `README.md` – deployment instructions

## ✅ Prerequisites

- AWS account and permission to launch EC2 instances
- Familiarity with SSH and basic Linux commands
- A Security Group that allows inbound traffic on:
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)
  - Port 5678 (n8n default)
- Domain or subdomain (optional, [DuckDNS](https://www.duckdns.org) recommended for free SSL)

## ☁️ Launching an EC2 Instance

1. **Choose Amazon Linux 2 AMI** when creating your EC2 instance.
2. **Add Inbound Rules** to your Security Group:
   - SSH: TCP port 22
   - HTTP: TCP port 80
   - HTTPS: TCP port 443
   - Custom TCP: port 5678

## ⚙️ Setting Up the Instance

SSH into your EC2 instance and run the following commands:

```bash
# Install Docker
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
newgrp docker  # or log out/in to apply group change

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set up project directory
mkdir -p ~/n8n && cd ~/n8n
mkdir -p certs config

# Create a Docker volume for persistent data
docker volume create n8n_data
```

## 🔐 Initial Setup

1. **Environment Variables**:
   | Variable | Description |
   | -------------------- | ------------------------------------------- |
   | `N8N_HOST` | Public hostname (used for webhooks and SSL) |
   | `N8N_URL` | Full external URL used for tunnel/webhooks |
   | `N8N_ENCRYPTION_KEY` | 32 Bit Encryption key |
   | `DUCKDNS_TOKEN` | The token provided by Duck DNS |
   | `CERTBOT_EMAIL` | Use your email for cert registration |

- For information regarding N8N variables, see [N8N Docs](https://docs.n8n.io/hosting/configuration/environment-variables)

Update the `.env` file before deploying. Example:

```env
# Required Configuration
N8N_HOST=your-subdomain.duckdns.org
N8N_URL=https://your-subdomain.duckdns.org/
N8N_ENCRYPTION_KEY=generate-a-random-32-character-key
DUCKDNS_TOKEN=your-duckdns-token
CERTBOT_EMAIL=your-email@example.com
```

```bash
# Generate encryption key
openssl rand -base64 32

# Edit your .env file
nano .env
```

2. **Security Notes**:
   - Never commit `.env` file to version control
   - Keep your DuckDNS token secure
   - Change default passwords immediately
   - Generate strong encryption keys

## 🧱 Docker Compose Setup

Use Sample `docker-compose.yaml`:

```bash
nano docker-compose.yaml
```

## 🚀 Starting n8n

Make sure your `.env` file is present in the same directory, then run:

```bash
docker-compose up -d
```

Visit your server's public IP or domain:

- `http://<your-ec2-ip>:5678`
- or `https://your-subdomain.duckdns.org` if using SSL

## ⚠️ Important Considerations and Gotchas

### Data Persistence

- **Docker Volumes**: While Docker volumes persist data between container restarts, they are stored locally on the EC2 instance. If the instance is terminated, **all data will be lost**.
- **Backup Critical**: Regular backups are essential. Consider implementing one of these backup strategies:

  ```bash
  # Option 1: Manual backup of n8n data volume to a tar file
  docker run --rm -v n8n_data:/source -v /path/to/backup:/backup alpine tar -czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz -C /source .

  # Option 2: Using AWS CLI to backup to S3 (recommended)
  aws s3 cp /path/to/backup/n8n-backup-$(date +%Y%m%d).tar.gz s3://your-bucket/backups/
  ```

### Instance Management

- **Stop vs. Terminate**:
  - 'Stopping' an EC2 instance is safe - data persists
  - 'Terminating' an EC2 instance will permanently delete all data
  - Consider using EBS volumes for critical data
- **IP Address Changes**:
  - EC2 public IP changes on instance restart
  - Use Elastic IP (not free tier) or DuckDNS for stable addressing
  - Update DNS records after IP changes

### 🔒 Security Best Practices

- Always use strong credentials for all users
- Never expose n8n publicly without basic authentication
- Consider using a reverse proxy (e.g. NGINX) with Let's Encrypt SSL
- Keep your containers updated regularly:

### SSL Certificates

- **Certificate Location**: Stored in the `./certs` volume
- **Renewal Timing**: Certificates expire every 90 days
- **Container Restart**: Required after certificate renewal
- **Port Availability**: Ports 80 and 443 must be free during renewal
- **OPTIONAL Automatic Certificate Renewal**:
  - Add to crontab (run as root)
    0 0 1 \* \* docker exec n8n_n8n_1 certbot renew --quiet && docker restart n8n_n8n_1

### Resource Limitations

- **Free Tier Constraints**:
  - t2.micro has limited CPU credits
  - Performance may degrade under heavy load
  - Monitor CPU credit balance
- **Memory Management**:
  - n8n can use significant memory with many workflows
  - Monitor memory usage
  - Consider setting Docker memory limits

### Network Considerations

- **Firewall Rules**:
  - Security group changes take effect immediately
  - Double-check ports 80/443 are open for SSL
  - Limit SSH access to known IPs
- **DuckDNS Updates**:
  - DNS propagation can take up to 5 minutes
  - Verify DNS records after instance restarts

### Best Practices

- **Regular Maintenance**:
  ```bash
  # Create a maintenance checklist script
  #!/bin/bash
  # Check disk space
  df -h
  # Check Docker volume usage
  docker system df
  # View logs for errors
  docker-compose logs --tail=100 n8n
  # Check certificate expiry
  certbot certificates
  ```
- **Monitoring**:
  - Set up AWS CloudWatch basic monitoring (free tier)
  - Monitor disk usage
  - Check certificate expiration dates
  - Monitor n8n process health

### Recovery Procedures

- **Volume Backup Recovery**:

  ```bash
  # Stop the container
  docker-compose down

  # Restore from backup
  docker run --rm -v n8n_data:/target -v /path/to/backup:/backup alpine sh -c "cd /target && tar xzf /backup/n8n-backup-YYYYMMDD.tar.gz"

  # Restart the container
  docker-compose up -d
  ```

### Cost Management

- **Free Tier Limits**:
  - Monitor AWS billing dashboard
  - Set up billing alerts
  - Be cautious with EBS volume size
  - Remember Elastic IPs are not free when unused

### Upgrading n8n

- **Before Upgrading**:
  - Always backup data
  - Read release notes
  - Test on non-production if possible
  ```bash
  # Backup before upgrade
  docker-compose down
  # Create backup
  docker run --rm -v n8n_data:/source -v /path/to/backup:/backup alpine tar -czf /backup/pre-upgrade-$(date +%Y%m%d).tar.gz -C /source .
  # Pull new version
  docker-compose pull
  # Start with new version
  docker-compose up -d
  ```

### Common Issues

- **Container Won't Start**:
  - Use `docker-compose logs -f` to view logs
  - Check if ports are already in use
  - Verify volume permissions
  - Check Docker logs: `docker-compose logs n8n`
- **Can't access from browser?**
  - Verify public IP and correct port (5678 or 443 for HTTPS)
  - Check EC2 Security Group rules
  - Run `docker ps` to ensure the container is up
- **Permission denied?**
  - Make sure Docker was installed correctly
  - You may need to reboot after adding your user to the Docker group
- **Data Disappears**:
  - Verify volume mounts
  - Check if using correct volume paths
  - Ensure backups are running

## 🙌 Credits

- [n8n.io](https://n8n.io)
- [Docker](https://docker.com)
- [AWS](https://aws.amazon.com)
- [DuckDNS](https://www.duckdns.org)
