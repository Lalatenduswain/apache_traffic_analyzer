#!/bin/bash

# === DEFAULT CONFIGURATION ===
CONFIG_FILE="/etc/apache2/traffic_analyzer.conf"
DEFAULT_LOG_FILES=("/var/log/apache2/access.log" "/var/log/apache2/access.log.1")
DEFAULT_OUTPUT_DIR="/opt/log_output"
DEFAULT_DATE_FILTER=$(date -d "yesterday" +%d/%b/%Y)
DEFAULT_MAX_REQ_THRESHOLD=1000
DEFAULT_ALERT_EMAIL="admin@example.com"
DEFAULT_ENABLE_GEOIP=false
DEFAULT_RETENTION_DAYS=30
ERROR_LOG="/var/log/traffic_analyzer_errors.log"

# === LOAD CONFIG FILE ===
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# === OVERRIDE WITH COMMAND LINE ARGS ===
LOG_FILES=("${@:-${DEFAULT_LOG_FILES[@]}}")
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
DATE_FILTER="${DATE_FILTER:-$DEFAULT_DATE_FILTER}"
MAX_REQ_THRESHOLD="${MAX_REQ_THRESHOLD:-$DEFAULT_MAX_REQ_THRESHOLD}"
ALERT_EMAIL="${ALERT_EMAIL:-$DEFAULT_ALERT_EMAIL}"
ENABLE_GEOIP="${ENABLE_GEOIP:-$DEFAULT_ENABLE_GEOIP}"
RETENTION_DAYS="${RETENTION_DAYS:-$DEFAULT_RETENTION_DAYS}"

# === SETUP ===
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/apache2-traffic-report-${DATE_FILTER//\//-}-${TIMESTAMP}.log"
TEMP_DIR="/tmp/traffic_analyzer_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR" || { echo "Error: Failed to create directories" >> "$ERROR_LOG"; exit 1; }

# === ERROR HANDLING ===
log_error() {
    echo "[$(date)] ERROR: $1" >> "$ERROR_LOG"
}

# === BACKUP LOG FILES ===
backup_logs() {
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            cp "$log" "$TEMP_DIR/$(basename "$log").backup" || log_error "Failed to backup $log"
        else
            log_error "Log file $log not found"
        fi
    done
}

# === REPORT HEADER ===
{
    echo "🔍 Apache2 Traffic Analysis Report"
    echo "Log Files: ${LOG_FILES[*]}"
    echo "Date Filter: $DATE_FILTER"
    echo "Generated at: $(date)"
    echo "=========================================="
} > "$OUTPUT_FILE"

# === CONCURRENT ANALYSIS FUNCTIONS ===
analyze_top_ips() {
    local temp_file="$TEMP_DIR/top_ips.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" '$4 ~ date {print $1}' "$log"
        fi
    done | sort | uniq -c | sort -nr | head -20 > "$temp_file"
    echo -e "\n🌐 Top 20 IP Addresses:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_urls() {
    local temp_file="$TEMP_DIR/top_urls.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" '$4 ~ date {print $7}' "$log"
        fi
    done | sort | uniq -c | sort -nr | head -20 > "$temp_file"
    echo -e "\n📄 Top 20 Requested URLs:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_status_codes() {
    local temp_file="$TEMP_DIR/status_codes.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" '$4 ~ date {print $9}' "$log"
        fi
    done | sort | uniq -c | sort -nr > "$temp_file"
    echo -e "\n📦 HTTP Status Code Summary:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_methods() {
    local temp_file="$TEMP_DIR/methods.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" '$4 ~ date {print $6}' "$log" | tr -d '"'
        fi
    done | sort | uniq -c | sort -nr > "$temp_file"
    echo -e "\n⚙️ HTTP Method Breakdown:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_peak_time() {
    local temp_file="$TEMP_DIR/peak_time.txt"
    local count=0
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            count=$((count + $(grep "${DATE_FILTER}:06:3" "$log" | wc -l)))
        fi
    done
    echo -e "\n⏱️ Total Requests at ~06:30: $count" >> "$OUTPUT_FILE"
}

analyze_time_range() {
    local temp_file="$TEMP_DIR/time_range.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            grep "${DATE_FILTER}:06:3[0-5]" "$log"
        fi
    done > "$temp_file"
    echo -e "\n📋 Raw Requests Between 06:30–06:35:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_user_agents() {
    local temp_file="$TEMP_DIR/user_agents.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" -F\" '$0 ~ date {print $6}' "$log"
        fi
    done | sort | uniq -c | sort -nr | head -20 > "$temp_file"
    echo -e "\n🧑‍💻 Top 20 User Agents:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_high_traffic_ips() {
    local temp_file="$TEMP_DIR/high_traffic_ips.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            awk -v date="$DATE_FILTER" '$4 ~ date {print $1}' "$log"
        fi
    done | sort | uniq -c | sort -nr | awk '$1 > 100' > "$temp_file"
    echo -e "\n🚨 IPs With >100 Requests:" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_suspicious() {
    local temp_file="$TEMP_DIR/suspicious.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            grep -Ei "${DATE_FILTER}.*(wp-login|xmlrpc|\.env|\.git|phpmyadmin|admin|\.sql)" "$log"
        fi
    done > "$temp_file"
    echo -e "\n🕵️ Suspicious Requests (wp-login, .git, etc.):" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_per_minute() {
    local temp_file="$TEMP_DIR/per_minute.txt"
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            grep "${DATE_FILTER}:06:" "$log" | awk '{print $4}' | cut -d: -f2-4
        fi
    done | sort | uniq -c > "$temp_file"
    echo -e "\n📊 Per-Minute Request Count (06:00–06:59):" >> "$OUTPUT_FILE"
    cat "$temp_file" >> "$OUTPUT_FILE"
}

analyze_geoip() {
    if [ "$ENABLE_GEOIP" = true ]; then
        local temp_file="$TEMP_DIR/geoip.txt"
        for log in "${LOG_FILES[@]}"; do
            if [ -f "$log" ]; then
                awk -v date="$DATE_FILTER" '$4 ~ date {print $1}' "$log"
            fi
        done | sort | uniq -c | sort -nr | head -5 | awk '{print $2}' | while read ip; do
            LOC=$(curl -s --connect-timeout 5 "http://ip-api.com/line/$ip?fields=country,regionName,city" | paste -s -d, -)
            echo "$ip → $LOC"
        done > "$temp_file"
        echo -e "\n🌍 Geolocation for Top 5 IPs:" >> "$OUTPUT_FILE"
        cat "$temp_file" >> "$OUTPUT_FILE"
    fi
}

# === SUMMARY STATISTICS ===
calculate_summary() {
    local total_requests=0
    local unique_ips=0
    local error_count=0
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            total_requests=$((total_requests + $(awk -v date="$DATE_FILTER" '$4 ~ date' "$log" | wc -l)))
            unique_ips=$((unique_ips + $(awk -v date="$DATE_FILTER" '$4 ~ date {print $1}' "$log" | sort | uniq | wc -l)))
            error_count=$((error_count + $(awk -v date="$DATE_FILTER" '$4 ~ date && $9 ~ /^(4|5)/' "$log" | wc -l)))
        fi
    done
    {
        echo -e "\n📈 Summary Statistics:"
        echo "Total Requests: $total_requests"
        echo "Unique IPs: $unique_ips"
        echo "Error Responses (4xx/5xx): $error_count"
    } >> "$OUTPUT_FILE"
}

# === EXECUTE ANALYSES CONCURRENTLY ===
backup_logs
analyze_top_ips &
analyze_urls &
analyze_status_codes &
analyze_methods &
analyze_peak_time &
analyze_time_range &
analyze_user_agents &
analyze_high_traffic_ips &
analyze_suspicious &
analyze_per_minute &
analyze_geoip &
wait

# === CALCULATE SUMMARY ===
calculate_summary

# === ALERTING ===
TOTAL_REQ=$(awk '{sum+=$1} END {print sum}' "$TEMP_DIR/high_traffic_ips.txt" 2>/dev/null || echo 0)
if [ "$TOTAL_REQ" -gt "$MAX_REQ_THRESHOLD" ]; then
    {
        echo -e "\n🚨 ALERT: High traffic detected (${TOTAL_REQ} requests)"
        echo "Top 5 IPs:"
        head -5 "$TEMP_DIR/high_traffic_ips.txt"
    } >> "$OUTPUT_FILE"
    if command -v mail >/dev/null; then
        mail -s "Apache Traffic Alert: $TOTAL_REQ requests" "$ALERT_EMAIL" < "$OUTPUT_FILE" || log_error "Failed to send alert email"
    else
        log_error "Mail command not found"
    fi
fi

# === CLEANUP OLD REPORTS ===
find "$OUTPUT_DIR" -name "apache2-traffic-report-*.log" -mtime +"$RETENTION_DAYS" -exec gzip {} \; || log_error "Failed to compress old reports"
find "$OUTPUT_DIR" -name "apache2-traffic-report-*.log.gz" -mtime +"$((RETENTION_DAYS * 2))" -delete || log_error "Failed to delete old compressed reports"

# === CLEANUP TEMP FILES ===
rm -rf "$TEMP_DIR" || log_error "Failed to clean up temp directory"

# === FINAL OUTPUT ===
echo -e "\n✅ Report saved to: $OUTPUT_FILE"
