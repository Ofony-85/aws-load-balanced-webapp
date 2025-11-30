#!/bin/bash

set -e
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

log_info "Starting deployment with Amazon Linux 2023..."

# Check AWS CLI
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured"
    exit 1
fi

AWS_REGION=$(aws configure get region)
MY_IP=$(curl -s https://checkip.amazonaws.com)
log_success "AWS Region: $AWS_REGION, Your IP: $MY_IP"

# Get VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNETS=($(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0:2].SubnetId' --output text))
SUBNET_1=${SUBNETS[0]}
SUBNET_2=${SUBNETS[1]}

log_success "VPC: $VPC_ID"
log_success "Subnets: $SUBNET_1, $SUBNET_2"

# Create key pair
KEY_NAME="webapp-key-$(date +%s)"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
chmod 400 $KEY_NAME.pem
log_success "Key created: $KEY_NAME.pem"

# Create security groups
ALB_SG_NAME="webapp-alb-sg-$(date +%s)"
ALB_SG_ID=$(aws ec2 create-security-group --group-name $ALB_SG_NAME --description "ALB security group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null
log_success "ALB SG: $ALB_SG_ID"

EC2_SG_NAME="webapp-ec2-sg-$(date +%s)"
EC2_SG_ID=$(aws ec2 create-security-group --group-name $EC2_SG_NAME --description "EC2 security group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 80 --source-group $ALB_SG_ID > /dev/null
aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr $MY_IP/32 > /dev/null
log_success "EC2 SG: $EC2_SG_ID"

# Get Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
log_success "AMI: $AMI_ID"

# Create user data with AL2023 syntax
cat > user-data.sh << 'USERDATA'
#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Started at $(date) ==="

# Update and install packages (AL2023 uses dnf)
dnf update -y
dnf install -y nginx python3 python3-pip

# Install Flask
pip3 install flask

# Create app
mkdir -p /opt/webapp
cat << 'FLASKAPP' > /opt/webapp/app.py
from flask import Flask, jsonify
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    hostname = socket.gethostname()
    return f'''<!DOCTYPE html>
<html><head><title>Server: {hostname}</title>
<style>
body {{font-family: Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
      display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0;}}
.container {{background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 600px;}}
h1 {{color: #667eea; text-align: center;}}
.info {{background: #f8f9fa; border-left: 4px solid #667eea; padding: 20px; margin: 15px 0; border-radius: 8px;}}
.label {{font-weight: bold; color: #555;}}
.value {{font-size: 1.2em; color: #333; margin-top: 5px;}}
button {{background: #667eea; color: white; border: none; padding: 12px 30px; border-radius: 8px; 
         cursor: pointer; font-size: 1em; width: 100%; margin-top: 20px;}}
button:hover {{background: #764ba2;}}
</style></head><body>
<div class="container">
<h1>🖥️ Server Information</h1>
<div class="info"><div class="label">Hostname:</div><div class="value">{hostname}</div></div>
<div class="info"><div class="label">IP Address:</div><div class="value">{socket.gethostbyname(hostname)}</div></div>
<div class="info"><div class="label">Time:</div><div class="value">{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</div></div>
<button onclick="location.reload()">🔄 Refresh to See Load Balancing</button>
</div></body></html>'''

@app.route('/health')
def health():
    return jsonify({{'status': 'healthy', 'hostname': socket.gethostname()}}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
FLASKAPP

# Configure Nginx
cat << 'NGINXCONF' > /etc/nginx/conf.d/webapp.conf
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
    }
    location /health {
        proxy_pass http://127.0.0.1:5000/health;
    }
}
NGINXCONF

# Create systemd service
cat << 'SYSTEMD' > /etc/systemd/system/webapp.service
[Unit]
Description=Flask App
After=network.target
[Service]
ExecStart=/usr/bin/python3 /opt/webapp/app.py
WorkingDirectory=/opt/webapp
Restart=always
[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable --now webapp
systemctl enable --now nginx

echo "=== Completed at $(date) ==="
USERDATA

# Launch instances
log_info "Launching 3 instances..."
declare -a INSTANCE_IDS
for i in {1..3}; do
    INST=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t2.micro --key-name $KEY_NAME \
        --security-group-ids $EC2_SG_ID --subnet-id $SUBNET_1 --user-data file://user-data.sh \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=WebApp-Server-$i}]" \
        --query 'Instances[0].InstanceId' --output text)
    INSTANCE_IDS+=("$INST")
    log_success "Instance $i: $INST"
    SUBNET_1=$SUBNET_2
    SUBNET_2=${SUBNETS[0]}
done

aws ec2 wait instance-running --instance-ids "${INSTANCE_IDS[@]}"
log_success "All instances running"

# Create target group
TARGET_GROUP_NAME="webapp-tg-$(date +%s)"
TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name $TARGET_GROUP_NAME --protocol HTTP --port 80 \
    --vpc-id $VPC_ID --health-check-path /health --query 'TargetGroups[0].TargetGroupArn' --output text)
log_success "Target group: $TARGET_GROUP_ARN"

# Register targets
TARGETS=$(printf "Id=%s " "${INSTANCE_IDS[@]}")
aws elbv2 register-targets --target-group-arn $TARGET_GROUP_ARN --targets $TARGETS
log_success "Targets registered"

# Create load balancer
ALB_NAME="webapp-alb-$(date +%s)"
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer --name $ALB_NAME --subnets ${SUBNETS[0]} ${SUBNETS[1]} \
    --security-groups $ALB_SG_ID --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $LOAD_BALANCER_ARN \
    --query 'LoadBalancers[0].DNSName' --output text)
log_success "Load balancer: $LB_DNS"

# Create listener
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $LOAD_BALANCER_ARN --protocol HTTP --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN --query 'Listeners[0].ListenerArn' --output text)
log_success "Listener created"

# Save config
cat > deployment-config.txt << EOF
VPC_ID=$VPC_ID
SUBNET_1=${SUBNETS[0]}
SUBNET_2=${SUBNETS[1]}
ALB_SG_ID=$ALB_SG_ID
ALB_SG_NAME=$ALB_SG_NAME
EC2_SG_ID=$EC2_SG_ID
EC2_SG_NAME=$EC2_SG_NAME
KEY_NAME=$KEY_NAME
INSTANCE_1=${INSTANCE_IDS[0]}
INSTANCE_2=${INSTANCE_IDS[1]}
INSTANCE_3=${INSTANCE_IDS[2]}
LOAD_BALANCER_ARN=$LOAD_BALANCER_ARN
ALB_NAME=$ALB_NAME
LB_DNS=$LB_DNS
TARGET_GROUP_ARN=$TARGET_GROUP_ARN
TARGET_GROUP_NAME=$TARGET_GROUP_NAME
LISTENER_ARN=$LISTENER_ARN
EOF

log_info "Waiting 3 minutes for setup..."
sleep 180

aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN --output table

echo ""
echo "================================================================================"
log_success "🎉 DEPLOYMENT COMPLETE!"
echo "================================================================================"
echo ""
echo "🌐 YOUR APPLICATION: http://$LB_DNS"
echo ""
echo "Open in browser and refresh to see load balancing!"
echo ""
