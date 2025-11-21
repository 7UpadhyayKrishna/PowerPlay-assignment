#!/bin/bash

LOG_FILE="/var/log/system_report.log"
EMAIL="krishnaupadhyay207@gmail.com" 

echo "System Report: $(date)" >> $LOG_FILE
echo "Uptime: $(uptime -p)" >> $LOG_FILE

DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
echo "Disk Usage: ${DISK_USAGE}%" >> $LOG_FILE

echo "Top 3 Processes:" >> $LOG_FILE
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 4 >> $LOG_FILE

if [ "$DISK_USAGE" -gt 5 ]; then
    /usr/local/bin/aws ses send-email \
        --from "$EMAIL" \
        --destination "ToAddresses=$EMAIL" \
        --message "Subject={Data=Disk Alert},Body={Text={Data=Disk usage on $(hostname) is at ${DISK_USAGE}%}}" \
        --region ap-south-1
fi
