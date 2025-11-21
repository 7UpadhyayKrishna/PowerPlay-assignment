# DevOps Intern Assignment — Powerplay

**Author:** Krishna Upadhyay  
**Region:** ap-south-1 (Mumbai)

## Objective

This assignment demonstrates practical DevOps skills including:
- Linux user management
- Web server setup
- System monitoring and automation
- CloudWatch log integration
- Systemd timers
- AWS SES-based alerting
- Clear documentation for reproducibility

---

## Part 1: Environment Setup

### Launch EC2 Instance
- **AMI:** Ubuntu 22.04 LTS
- **Instance Type:** t2.micro
- **Security Group:** SSH (22) + HTTP (80)

### SSH into Instance
```bash
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
```

### Create User and Grant Sudo
```bash
sudo adduser devops_intern
echo "devops_intern ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devops_intern
```

### Change Hostname
```bash
sudo hostnamectl set-hostname Krishna-devops
```

### Switch User
```bash
su - devops_intern
sudo whoami
```

### Deliverable
Screenshot showing:
- Hostname
- New user entry in `/etc/passwd`
- Output of `sudo whoami`

---

## Part 2: Simple Web Service

### Install Nginx
```bash
sudo apt update
sudo apt install nginx -y
```

### Fetch Metadata (IMDSv2)
```bash
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)

UPTIME=$(uptime -p)
```

### Create Webpage
```bash
sudo bash -c "cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>DevOps Assignment</title></head>
<body>
  <h1>DevOps Intern Assignment</h1>
  <p>Name: Krishna</p>
  <p>Instance ID: $INSTANCE_ID</p>
  <p>Server Uptime: $UPTIME</p>
</body>
</html>
EOF"
```

### Deliverable
Screenshot of webpage accessed via Public IP

---

## Part 3: Monitoring Script and Cron Job

### Create Script
**File:** `/usr/local/bin/system_report.sh`

```bash
#!/bin/bash
echo "--------------------------------------------------"
echo "System Report: $(date)"
echo "Uptime: $(uptime -p)"
echo "Disk Usage:"
df -h / | awk 'NR==2 {print $5}'
echo "Top 3 Processes:"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 4
echo "--------------------------------------------------"
```

### Make Executable
```bash
sudo chmod +x /usr/local/bin/system_report.sh
```

### Create Log Immediately
```bash
sudo /usr/local/bin/system_report.sh >> /var/log/system_report.log
```

### Create Cron Job
```bash
sudo crontab -e
```

Add the following line:
```
*/5 * * * * /usr/local/bin/system_report.sh >> /var/log/system_report.log 2>&1
```

### Deliverables
- Screenshot of `sudo crontab -l`
- Screenshot of `/var/log/system_report.log` (showing at least two entries)

---

## Part 4: AWS CloudWatch Integration

### Install AWS CLI v2
```bash
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configure AWS
```bash
/usr/local/bin/aws configure
```
- **Region:** ap-south-1

### Create CloudWatch Group and Stream
```bash
/usr/local/bin/aws logs create-log-group --log-group-name /devops/intern-metrics

/usr/local/bin/aws logs create-log-stream \
  --log-group-name /devops/intern-metrics \
  --log-stream-name system-logs
```

### Push Logs to CloudWatch
```bash
TIMESTAMP=$(date +%s000)
MESSAGE=$(tail -n 10 /var/log/system_report.log | tr '\n' ' ' | tr -d ',')

/usr/local/bin/aws logs put-log-events \
  --log-group-name /devops/intern-metrics \
  --log-stream-name system-logs \
  --log-events timestamp=$TIMESTAMP,message="$MESSAGE"
```

### Deliverables
- Screenshot of AWS CLI command
- Screenshot of log entries visible in CloudWatch

---

## Bonus Task 1: Replace Cron with Systemd Timer

### Service File
**File:** `/etc/systemd/system/system-report.service`

```ini
[Unit]
Description=System Report Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/system_report.sh
```

### Timer File
**File:** `/etc/systemd/system/system-report.timer`

```ini
[Unit]
Description=Run System Report every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=system-report.service

[Install]
WantedBy=timers.target
```

### Enable Timer
```bash
sudo systemctl daemon-reload
sudo systemctl enable system-report.timer
sudo systemctl start system-report.timer
sudo crontab -r
```

### Deliverable
Screenshot of:
```bash
sudo systemctl list-timers --all | grep system-report
```

---

## Bonus Task 2: Email Alert (AWS SES)

### Verify Email
```bash
/usr/local/bin/aws ses verify-email-identity \
  --email-address your-email@gmail.com \
  --region ap-south-1
```

### Update Script
Add inside `/usr/local/bin/system_report.sh`:

```bash
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

if [ "$DISK_USAGE" -gt 80 ]; then
  /usr/local/bin/aws ses send-email \
    --from "your-email@gmail.com" \
    --destination "ToAddresses=your-email@gmail.com" \
    --message "Subject={Data=Disk Alert},Body={Text={Data=Disk usage is at ${DISK_USAGE}%}}" \
    --region ap-south-1
fi
```

### Test Alert
Temporarily change condition:
```bash
if [ "$DISK_USAGE" -gt 5 ]; then
```

Run:
```bash
sudo /usr/local/bin/system_report.sh
```

Check inbox for alert email.

---

