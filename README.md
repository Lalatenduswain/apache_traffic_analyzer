# Apache Traffic Analyzer 🚀

Welcome to **Apache Traffic Analyzer**, a powerful Bash script designed to analyze Apache2 access logs and generate detailed traffic reports. This tool helps system administrators monitor web server activity, detect suspicious requests, and identify high-traffic patterns with ease.

📌 **Features**  
- 🌐 **Top IP Analysis**: Identifies the top 20 IP addresses accessing your server.  
- 📄 **URL Insights**: Lists the top 20 requested URLs for a given date.  
- 📦 **HTTP Status Codes**: Summarizes HTTP response codes (e.g., 200, 404, 500).  
- ⚙️ **Request Methods**: Breaks down HTTP methods (GET, POST, etc.).  
- ⏱️ **Peak Traffic**: Counts requests around specific times (e.g., 06:30).  
- 📋 **Time Range Logs**: Extracts raw logs for specific time windows (e.g., 06:30–06:35).  
- 🧑‍💻 **User Agents**: Lists the top 20 user agents accessing your server.  
- 🚨 **High Traffic Alerts**: Flags IPs with over 100 requests and sends email alerts for high traffic.  
- 🕵️ **Suspicious Requests**: Detects potentially malicious requests (e.g., wp-login, .git).  
- 📊 **Per-Minute Traffic**: Analyzes request counts per minute for a specified hour.  
- 🌍 **Optional Geolocation**: Resolves IP locations using an external API (optional).  
- 📈 **Summary Statistics**: Provides total requests, unique IPs, and error counts.  
- 🔄 **Concurrent Processing**: Runs analyses in parallel for faster execution.  
- 🗃️ **Log Backup**: Creates backups of log files before processing.  
- 🗑️ **Report Retention**: Compresses old reports and deletes outdated ones.  
- ⚙️ **Config File Support**: Customizable via a configuration file.  
- 🛡️ **Error Handling**: Logs errors to a dedicated file for troubleshooting.

📖 **Installation Guide**  

### Prerequisites
Before running the script, ensure the following are installed and configured:

- **Operating System**: Linux (Ubuntu, Debian, CentOS, etc.)
- **Bash**: Version 4.0 or higher (`bash --version`)
- **Apache2**: Access logs in Combined Log Format
- **Required Tools**:
  - `awk`, `grep`, `sort`, `uniq`, `cut`, `tr`: Usually pre-installed on Linux systems
  - `curl`: For optional geolocation (install with `sudo apt install curl` on Debian/Ubuntu or `sudo yum install curl` on CentOS)
  - `mail`: For email alerts (install with `sudo apt install mailutils` on Debian/Ubuntu or `sudo yum install mailx` on CentOS)
- **Permissions**:
  - Read access to Apache2 log files (e.g., `/var/log/apache2/access.log`)
  - Write access to the output directory (e.g., `/opt/log_output`)
  - Write access to the error log directory (e.g., `/var/log/`)
  - Sudo privileges if modifying system directories or installing packages
- **Optional**: Internet access for geolocation API calls (uses `http://ip-api.com`)

### Installation Steps
1. **Clone the Repository**  
   Clone the Apache Traffic Analyzer repository from GitHub:
   ```bash
   git clone https://github.com/Lalatenduswain/apache_traffic_analyzer
   cd apache_traffic_analyzer
   ```

2. **Set Execute Permissions**  
   Make the script executable:
   ```bash
   chmod +x apache_traffic_analyzer.sh
   ```

3. **Create Configuration File (Optional)**  
   Create a configuration file at `/etc/apache2/traffic_analyzer.conf` to customize settings:
   ```bash
   sudo mkdir -p /etc/apache2
   sudo nano /etc/apache2/traffic_analyzer.conf
   ```
   Example configuration:
   ```bash
   LOG_FILES=("/var/log/apache2/access.log" "/var/log/apache2/access.log.1")
   OUTPUT_DIR="/opt/log_output"
   MAX_REQ_THRESHOLD=1000
   ALERT_EMAIL="admin@example.com"
   ENABLE_GEOIP=false
   RETENTION_DAYS=30
   ```
   Save and exit. Adjust paths and settings as needed.

4. **Create Output Directory**  
   Ensure the output directory exists and is writable:
   ```bash
   sudo mkdir -p /opt/log_output
   sudo chown $(whoami):$(whoami) /opt/log_output
   ```

5. **Set Up Error Logging**  
   Ensure the error log directory is writable:
   ```bash
   sudo touch /var/log/traffic_analyzer_errors.log
   sudo chown $(whoami):$(whoami) /var/log/traffic_analyzer_errors.log
   ```

6. **Test the Script**  
   Run the script with default settings:
   ```bash
   ./apache_traffic_analyzer.sh
   ```
   Or specify custom log files:
   ```bash
   ./apache_traffic_analyzer.sh /var/log/apache2/access.log
   ```

7. **Schedule with Cron (Optional)**  
   Automate daily runs using cron:
   ```bash
   crontab -e
   ```
   Add the following to run daily at 1 AM:
   ```bash
   0 1 * * * /path/to/apache_traffic_analyzer.sh
   ```

🔍 **Script Explanation**  
The `apache_traffic_analyzer.sh` script automates the analysis of Apache2 access logs, generating a comprehensive report for a specified date (default: yesterday). Here's how it works:

- **Configuration**: Reads settings from `/etc/apache2/traffic_analyzer.conf` or command-line arguments. Key settings include log file paths, output directory, date filter, and alert thresholds.
- **Log Backup**: Creates backups of input log files in a temporary directory to prevent data loss.
- **Concurrent Analysis**: Processes multiple analyses (e.g., top IPs, URLs, status codes) in parallel using background jobs for efficiency.
- **Report Generation**: Writes results to a timestamped file in the output directory, including:
  - Top 20 IPs, URLs, and user agents
  - HTTP status codes and methods
  - Traffic counts for specific times
  - Suspicious request detection
  - Optional geolocation for top IPs
- **Summary Statistics**: Calculates total requests, unique IPs, and error counts.
- **Alerting**: Sends email alerts if traffic exceeds a threshold, including details like top IPs.
- **Retention**: Compresses old reports after a specified period (default: 30 days) and deletes older compressed files.
- **Error Handling**: Logs issues (e.g., missing files, failed commands) to `/var/log/traffic_analyzer_errors.log`.

The script is designed for flexibility, supporting multiple log files, customizable thresholds, and optional features like geolocation. It's ideal for system administrators monitoring Apache2 servers.

📋 **Usage**  
```bash
./apache_traffic_analyzer.sh [log_file1 log_file2 ...]
```
- If no log files are specified, it uses defaults from the config file or `/var/log/apache2/access.log`.
- Output is saved to `/opt/log_output/apache2-traffic-report-YYYY-MM-DD-TIMESTAMP.log`.
- Check `/var/log/traffic_analyzer_errors.log` for any issues.

⚠️ **Disclaimer | Running the Script**  
**Author:** Lalatendu Swain | [GitHub](https://github.com/Lalatenduswain) | [Website](https://blog.lalatendu.info/)

This script is provided as-is and may require modifications or updates based on your specific environment and requirements. Use it at your own risk. The authors of the script are not liable for any damages or issues caused by its usage.

💖 **Support & Donations**  
If you find this script useful and want to show your appreciation, you can donate via [Buy Me a Coffee](https://www.buymeacoffee.com/lalatendu.swain).

Encountering issues? Don't hesitate to submit an issue on our [GitHub page](https://github.com/Lalatenduswain/apache_traffic_analyzer/issues).
