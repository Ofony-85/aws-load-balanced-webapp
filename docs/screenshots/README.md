# Screenshots Directory

This directory should contain 4 screenshots demonstrating the application:

## Required Screenshots

1. **homepage-server1.png**
   - Screenshot of the application homepage showing Server 1
   - Hostname: ip-172-31-2-46
   - IP: 172.31.2.46

2. **homepage-server2-loadbalancing.png**
   - Screenshot after clicking refresh, showing Server 2
   - Hostname: ip-172-31-6-141
   - IP: 172.31.6.141
   - **This demonstrates load balancing in action!**

3. **health-endpoint.png**
   - Screenshot of /health endpoint
   - Shows JSON: {"hostname":"ip-172-31-6-141","status":"healthy"}

4. **aws-ec2-console.png**
   - Screenshot of AWS EC2 Console
   - Shows 3 WebApp-Server instances running
   - Status checks: 2/2 passed

## How to Add Screenshots

### From Windows:

1. Save your screenshots to your computer
2. Open File Explorer
3. Navigate to: `\\wsl$\Ubuntu\home\ofonime\webapp-production\aws-load-balanced-webapp\docs\screenshots\`
4. Copy your 4 screenshots here with the exact names above

### From WSL:
```bash
# If screenshots are in Windows Downloads:
cp /mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/screenshot1.png docs/screenshots/homepage-server1.png
cp /mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/screenshot2.png docs/screenshots/homepage-server2-loadbalancing.png
cp /mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/screenshot3.png docs/screenshots/health-endpoint.png
cp /mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/screenshot4.png docs/screenshots/aws-ec2-console.png
```

### Then commit and push:
```bash
git add docs/screenshots/*.png
git commit -m "Add application screenshots"
git push origin main
```
