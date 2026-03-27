#!/bin/bash

LOG_FILE="/var/log/health_monitor.log"
SERVICE_FILE="services.txt"
DRY_RUN=false

# Check for --dry-run flag
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in DRY-RUN mode (no changes will be made)"
fi

# Check if services.txt exists and is not empty
if [[ ! -f "$SERVICE_FILE" || ! -s "$SERVICE_FILE" ]]; then
    echo "Error: services.txt not found or empty!"
    exit 1
fi

total=0
healthy=0
recovered=0
failed=0

# Function to log events
log_event() {
    local service=$1
    local status=$2
    local severity=$3
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$severity] $service - $status" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Read services one by one
while read -r service
do
    ((total++))

    status=$(systemctl is-active "$service" 2>/dev/null)

    if [[ "$status" == "active" ]]; then
        echo "$service is running"
        ((healthy++))
    else
        echo "$service is NOT running"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] Would restart $service"
            log_event "$service" "SIMULATED_RECOVERY" "INFO"
            ((recovered++))
        else
            echo "Restarting $service..."
            sudo systemctl restart "$service"
            sleep 5

            new_status=$(systemctl is-active "$service" 2>/dev/null)

            if [[ "$new_status" == "active" ]]; then
                echo "$service recovered"
                log_event "$service" "RECOVERED" "INFO"
                ((recovered++))
            else
                echo "$service failed to recover"
                log_event "$service" "FAILED" "ERROR"
                ((failed++))
            fi
        fi
    fi

done < "$SERVICE_FILE"

# Print summary
echo ""
echo "===== SUMMARY ====="
echo "Total Checked : $total"
echo "Healthy       : $healthy"
echo "Recovered     : $recovered"
echo "Failed        : $failed"
