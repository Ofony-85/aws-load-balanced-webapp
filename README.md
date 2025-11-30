# AWS Load-Balanced Web Application

A production-ready, highly available web application deployed on AWS using EC2 instances behind an Application Load Balancer.

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20ALB-orange)
![Python](https://img.shields.io/badge/Python-3.9-blue)

## 🌐 Live Demo

**Application URL:** `http://webapp-alb-1764231315-1467904260.us-east-1.elb.amazonaws.com`

Click "Refresh" to see load balancing in action!

## 📊 Project Overview

This project demonstrates a **production-grade AWS architecture** with:
- ✅ 3 EC2 instances across multiple availability zones
- ✅ Application Load Balancer for traffic distribution
- ✅ Automated deployment with Infrastructure as Code
- ✅ Health monitoring and auto-failover capabilities
- ✅ Beautiful, responsive web interface

### Architecture Diagram

```
                          INTERNET
                             │
                             ▼
                ┌────────────────────────┐
                │  Application Load      │
                │  Balancer (ALB)        │
                └────────────────────────┘
                             │
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ EC2 Server-1│  │ EC2 Server-2│  │ EC2 Server-3│
    │   Nginx     │  │   Nginx     │  │   Nginx     │
    │   Flask     │  │   Flask     │  │   Flask     │
    └─────────────┘  └─────────────┘  └─────────────┘
```

[View detailed architecture diagram](docs/architecture.txt)

## 🛠️ Technical Stack

| Component | Technology |
|-----------|-----------|
| **Cloud Provider** | AWS (EC2, ALB, VPC) |
| **Operating System** | Amazon Linux 2023 |
| **Web Server** | Nginx 1.24+ |
| **Application** | Python 3.9 + Flask 3.0 |
| **Infrastructure** | Bash scripting (IaC) |
| **Load Balancer** | AWS Application Load Balancer |

## 🚀 Quick Start

### Prerequisites

- AWS Account
- AWS CLI installed and configured
- Bash shell (Linux/Mac/WSL)

### Deploy in 3 Steps

```bash
# 1. Clone repository
git clone https://github.com/YOUR_GITHUB_USERNAME/aws-load-balanced-webapp.git
cd aws-load-balanced-webapp

# 2. Make script executable
chmod +x scripts/deploy.sh

# 3. Deploy!
./scripts/deploy.sh
```

**Deployment time:** ~8 minutes

### Access Your Application

After deployment completes, the script will display your URL:

```
http://your-load-balancer-XXXXX.us-east-1.elb.amazonaws.com
```

## 📸 Screenshots

### Application Homepage
![Homepage]("C:\Users\OFONIME\OneDrive\Pictures\Screenshots 1\screenshot-homepage.png.png")

### Load Balancing in Action
![Load Balancing]("C:\Users\OFONIME\OneDrive\Pictures\Screenshots\screenshot-loadbalancing.png.png")

### Health Check Endpoint
![Health Check]("C:\Users\OFONIME\OneDrive\Pictures\Screenshots\screenshot-health.png.png")

## 🏗️ Infrastructure Details

### Current Deployment

**Load Balancer:**
- DNS: `webapp-alb-1764231315-1467904260.us-east-1.elb.amazonaws.com`
- ARN: `arn:aws:elasticloadbalancing:us-east-1:477094921093:loadbalancer/app/webapp-alb-1764231315/30b5975c5a001981`

**EC2 Instances:**
- Instance 1: `i-0570ab95ea81d4676` (`100.29.190.124`)
- Instance 2: `i-061e3e516e8ec6231` (`54.224.99.151`)
- Instance 3: `i-00562cca4f818bc87` (`3.238.7.247`)

**Security Groups:**
- ALB: `sg-0c05bb26b88fbbb08`
- EC2: `sg-09edff58f76faeb95`

### Health Check Configuration

- **Endpoint:** `/health`
- **Protocol:** HTTP
- **Interval:** 30 seconds
- **Timeout:** 5 seconds
- **Healthy threshold:** 2 checks
- **Unhealthy threshold:** 2 checks

## 🔧 Features

### 1. Automated Deployment
One-command deployment script handles:
- VPC and subnet discovery
- Security group creation and configuration
- SSH key pair generation
- EC2 instance provisioning
- Application installation and configuration
- Load balancer setup
- Health check configuration

### 2. High Availability
- Multi-AZ deployment across us-east-1a and us-east-1b
- Automatic failover if instance becomes unhealthy
- Health checks every 30 seconds
- Unhealthy instances automatically removed from pool

### 3. Load Balancing
- Round-robin traffic distribution
- Session persistence available
- Cross-zone load balancing enabled
- Automatic scaling support

### 4. Security
- Security groups restrict access
- SSH only from deployment machine
- HTTP only from ALB to instances
- ALB accepts HTTP from anywhere

### 5. Monitoring
- Health check endpoint at `/health`
- Real-time server information display
- CloudWatch integration ready

## 📁 Project Structure

```
aws-load-balanced-webapp/
├── app/
│   └── app.py                 # Flask application
├── scripts/
│   ├── deploy.sh              # Deployment automation
│   └── cleanup.sh             # Resource cleanup
├── docs/
│   ├── architecture.txt       # Architecture diagram
│   ├── TECHNICAL.md           # Technical documentation
│   ├── DEPLOYMENT_GUIDE.md    # Detailed deployment guide
│   └── screenshots/           # Application screenshots
├── README.md                  # This file
├── LICENSE                    # MIT License
└── .gitignore                 # Git ignore rules
```

## 💰 Cost Estimate

**Using AWS Free Tier:**
- t2.micro instances: **FREE** (750 hours/month first year)
- Application Load Balancer: **~$16/month**
- Data transfer: **Minimal** (<1GB)

**Total:** ~$16/month (or FREE for first year with new AWS account)

## 🧹 Cleanup

To delete all resources and avoid charges:

```bash
./scripts/cleanup.sh
```

Type `yes` when prompted to confirm deletion.

## 📚 Documentation

- [Architecture Diagram](docs/architecture.txt) - Visual architecture

## 🎓 Skills Demonstrated

This project showcases proficiency in:

- ☁️ **Cloud Computing:** AWS EC2, ELB, VPC, Security Groups
- 🔧 **DevOps:** Infrastructure as Code, automation, deployment
- 🐧 **Linux:** System administration, service management
- 🐍 **Python:** Flask web framework, REST APIs
- 🌐 **Web Servers:** Nginx reverse proxy configuration
- 🔒 **Security:** Network isolation, security group configuration
- 📊 **Architecture:** Load balancing, high availability, fault tolerance
- 📝 **Scripting:** Bash automation, error handling

## 🐛 Troubleshooting

### Instances showing as unhealthy

Wait 2-3 minutes for setup to complete. Check logs:

```bash
ssh -i webapp-key-*.pem ec2-user@INSTANCE_IP
sudo journalctl -u webapp -n 50
```

### Can't SSH into instances

Your IP may have changed. Update security group:

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
    --group-id sg-09edff58f76faeb95 \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP/32
```

### Load balancer not distributing traffic

Verify health checks are passing:

```bash
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:477094921093:targetgroup/webapp-tg-1764231307/e337e12dc689706d
```

## 🔮 Future Enhancements

- [ ] Add HTTPS/SSL with AWS Certificate Manager
- [ ] Implement Auto Scaling Group
- [ ] Add RDS database backend
- [ ] CloudFront CDN integration
- [ ] CloudWatch monitoring dashboards
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Blue-green deployment strategy
- [ ] Docker containerization

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## 📧 Contact

**Ofonime Offong**
- GitHub: [@ofonimeoffong](https://github.com/Ofony-85)
- LinkedIn: [Ofonime Offong](https://www.linkedin.com/in/ofonime-offong-139322a3/)
- Email: ofonyme3@gmail.com

---

⭐ **If this project helped you learn about AWS and cloud infrastructure, please give it a star!**

**Built with ❤️ using AWS, Python, and Open Source tools**
