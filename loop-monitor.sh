#!/bin/bash
# ============================================================
# loop-monitor.sh - Script giám sát hệ thống chạy nền
# Mô tả: Ghi thời gian hiện tại vào /tmp/monitor.log mỗi 5s
# Sử dụng: nohup ./loop-monitor.sh > /dev/null 2>&1 &
# ============================================================

LOG_FILE="/tmp/monitor.log"

echo "==== Monitor script started at $(date) ====" >> "$LOG_FILE"

while true; do
    echo "System time: $(date)" >> "$LOG_FILE"
    sleep 5
done
