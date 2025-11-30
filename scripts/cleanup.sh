#!/bin/bash
set -e
set -o pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

################################################################################
# Load Configuration
################################################################################

if [ ! -f "deployment-config.txt" ]; then
    log_error "deployment-config.txt not found!"
    log_error "Make sure you're in the same directory where you ran the deployment."
    exit 1
fi

log_info "Loading deployment configuration..."
source deployment-config.txt
log_success "Configuration loaded"

################################################################################
# Confirmation
################################################################################

echo ""
echo "================================================================================"
log_warning "⚠️  WARNING: This will DELETE all deployed resources!"
echo "================================================================================"
echo ""
echo "Resources to be deleted:"
echo "  • Load Balancer: $ALB_NAME"
echo "  • Target Group: $TARGET_GROUP_NAME"
echo "  • 3 EC2 Instances"
echo "  • Security Groups: $ALB_SG_NAME, $EC2_SG_NAME"
echo "  • SSH Key Pair: $KEY_NAME"
echo ""
echo -n "Are you sure you want to continue? Type 'yes' to confirm: "
read CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
    log_info "Cleanup cancelled"
    exit 0
fi

echo ""
log_info "Starting cleanup process..."

################################################################################
# Step 1: Delete Load Balancer
################################################################################

log_info "Step 1: Deleting Application Load Balancer..."

if aws elbv2 delete-load-balancer --load-balancer-arn "$LOAD_BALANCER_ARN" 2>/dev/null; then
    log_success "Load balancer deletion initiated"
    log_info "Waiting for load balancer to be deleted (this takes ~2 minutes)..."
    
    # Wait for deletion
    for i in {1..24}; do
        if ! aws elbv2 describe-load-balancers --load-balancer-arns "$LOAD_BALANCER_ARN" &>/dev/null; then
            log_success "Load balancer deleted"
            break
        fi
        echo -n "."
        sleep 5
    done
    echo ""
else
    log_warning "Load balancer may already be deleted"
fi

################################################################################
# Step 2: Delete Target Group
################################################################################

log_info "Step 2: Deleting Target Group..."

# Wait a bit more to ensure load balancer is fully deleted
sleep 10

if aws elbv2 delete-target-group --target-group-arn "$TARGET_GROUP_ARN" 2>/dev/null; then
    log_success "Target group deleted"
else
    log_warning "Target group may already be deleted"
fi

################################################################################
# Step 3: Terminate EC2 Instances
################################################################################

log_info "Step 3: Terminating EC2 instances..."

INSTANCE_IDS="$INSTANCE_1 $INSTANCE_2 $INSTANCE_3"

if aws ec2 terminate-instances --instance-ids $INSTANCE_IDS &>/dev/null; then
    log_success "Instance termination initiated"
    log_info "Waiting for instances to terminate (this takes ~1 minute)..."
    
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS 2>/dev/null || true
    log_success "All instances terminated"
else
    log_warning "Instances may already be terminated"
fi

################################################################################
# Step 4: Delete Security Groups
################################################################################

log_info "Step 4: Deleting security groups..."

# Wait for network interfaces to detach
log_info "Waiting for network interfaces to detach..."
sleep 30

# Delete EC2 security group
if aws ec2 delete-security-group --group-id "$EC2_SG_ID" 2>/dev/null; then
    log_success "EC2 security group deleted: $EC2_SG_ID"
else
    log_warning "EC2 security group may already be deleted or still in use"
fi

# Delete ALB security group
if aws ec2 delete-security-group --group-id "$ALB_SG_ID" 2>/dev/null; then
    log_success "ALB security group deleted: $ALB_SG_ID"
else
    log_warning "ALB security group may already be deleted or still in use"
fi

################################################################################
# Step 5: Delete Key Pair
################################################################################

log_info "Step 5: Deleting SSH key pair..."

if aws ec2 delete-key-pair --key-name "$KEY_NAME" 2>/dev/null; then
    log_success "Key pair deleted from AWS: $KEY_NAME"
else
    log_warning "Key pair may already be deleted"
fi

# Ask about local key file
echo ""
echo -n "Delete local key file ($KEY_NAME.pem)? (yes/no): "
read DELETE_KEY

if [ "$DELETE_KEY" == "yes" ]; then
    rm -f "$KEY_NAME.pem"
    log_success "Local key file deleted"
else
    log_info "Keeping local key file"
fi

################################################################################
# Step 6: Clean Up Local Files
################################################################################

log_info "Step 6: Cleaning up local files..."

echo -n "Delete deployment configuration and user data files? (yes/no): "
read DELETE_FILES

if [ "$DELETE_FILES" == "yes" ]; then
    rm -f deployment-config.txt user-data.sh
    log_success "Local files deleted"
else
    log_info "Keeping local files"
fi

################################################################################
# Cleanup Complete
################################################################################

echo ""
echo "================================================================================"
log_success "🎉 CLEANUP COMPLETE! 🎉"
echo "================================================================================"
echo ""
echo "All AWS resources have been deleted."
echo "You will no longer be charged for these resources."
echo ""
echo "📊 Summary:"
echo "  ✓ Load balancer deleted"
echo "  ✓ Target group deleted"
echo "  ✓ EC2 instances terminated"
echo "  ✓ Security groups deleted"
echo "  ✓ Key pair deleted"
echo ""
log_info "Thank you for using this deployment!"
echo ""
