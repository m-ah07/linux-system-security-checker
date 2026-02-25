#!/bin/bash

echo "Starting Enhanced Linux System Security Check..."
echo "================================================"

# Report files
report="security-report.txt"
html_report="security-report.html"

# Initialize report files (clear previous content)
> "$report"
> "$html_report"

# Function to escape HTML special characters
escape_html() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# Function to append a section to the text report only
append_to_report() {
    echo "$1" >> "$report"
}

# Function to append to both reports (with HTML escaping)
append_to_both() {
    echo "$1" >> "$report"
    echo "$1" | escape_html | sed 's/$/<br>/' >> "$html_report"
}

# Function to append command output to both reports
append_command_output() {
    local output
    output="$1"
    echo "$output" >> "$report"
    echo "$output" | escape_html | sed 's/$/<br>/' >> "$html_report"
}

# Generate HTML header with CSS
generate_html_header() {
    cat > "$html_report" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Linux Security Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #1a1a2e; color: #eee; }
        .container { max-width: 900px; margin: 0 auto; }
        h1 { color: #00d9ff; border-bottom: 2px solid #00d9ff; padding-bottom: 10px; }
        h2 { color: #e94560; margin-top: 25px; }
        .section { background: #16213e; padding: 15px; border-radius: 8px; margin: 15px 0; }
        pre { background: #0f3460; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; }
        .success { color: #4ecca3; }
        .warning { color: #ffc107; }
        .footer { margin-top: 30px; font-size: 12px; color: #888; }
    </style>
</head>
<body>
    <div class="container">
HTMLEOF
    echo "<h1>Linux Security Report - $(date)</h1>" >> "$html_report"
}

# Generate HTML footer
generate_html_footer() {
    echo "<div class='footer'>Report generated on $(date) by Linux System Security Checker</div>" >> "$html_report"
    echo "</div></body></html>" >> "$html_report"
}

# Call header at start
generate_html_header

# Add date to text report
echo "Security Report - $(date)" >> "$report"
append_to_report "========================================"

# Check for firewall status
echo "[+] Checking Firewall Status..."
append_to_both ""
append_to_both "Firewall Status:"
if command -v ufw &>/dev/null; then
    ufw_output=$(ufw status 2>/dev/null)
    if [ -n "$ufw_output" ]; then
        append_command_output "$ufw_output"
    else
        append_to_both "Could not retrieve UFW status (may require root)."
    fi
else
    append_to_both "UFW is not installed."
fi
append_to_both "---------------------------------------"

# Check file permissions
echo "[+] Checking Permissions of Sensitive Files..."
files=("/etc/passwd" "/etc/shadow" "/etc/hosts")
append_to_both "File Permissions:"
for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        file_info=$(ls -l "$file" 2>/dev/null)
        append_command_output "$file_info"
    else
        append_to_both "$file does not exist."
    fi
done
append_to_both "---------------------------------------"

# Check for inactive users (users with /bin/false or /usr/sbin/nologin - cannot login)
echo "[+] Checking for Inactive Users (no login shell)..."
append_to_both "Inactive Users (cannot login):"
inactive_users=$(awk -F: '{ if ($7 == "/bin/false" || $7 == "/usr/sbin/nologin") print $1 }' /etc/passwd 2>/dev/null)
if [ -n "$inactive_users" ]; then
    append_command_output "$inactive_users"
else
    append_to_both "(none found)"
fi
append_to_both "---------------------------------------"

# Check for users with login shells (active users - security relevant)
echo "[+] Checking for Users with Login Shells..."
append_to_both "Users with Login Shells (can login):"
active_users=$(awk -F: '{ if ($7 != "/bin/false" && $7 != "/usr/sbin/nologin" && $7 != "") print $1 }' /etc/passwd 2>/dev/null)
if [ -n "$active_users" ]; then
    append_command_output "$active_users"
else
    append_to_both "(none found)"
fi
append_to_both "---------------------------------------"

# Check for updates (support multiple package managers)
echo "[+] Checking for System Updates..."
append_to_both "System Updates:"
updates_found=false

if command -v apt &>/dev/null; then
    updates=$(apt list --upgradable 2>/dev/null | tail -n +2)
    if [ -n "$updates" ]; then
        append_command_output "The following packages can be updated:"
        append_command_output "$updates"
        updates_found=true
    fi
elif command -v dnf &>/dev/null; then
    dnf_output=$(dnf check-update 2>/dev/null || true)
    if echo "$dnf_output" | grep -qE '^[a-zA-Z0-9]'; then
        append_command_output "$dnf_output"
        updates_found=true
    fi
elif command -v yum &>/dev/null; then
    yum_output=$(yum check-update 2>/dev/null || true)
    if [ -n "$yum_output" ] && ! echo "$yum_output" | grep -q "No packages marked for update"; then
        append_command_output "$yum_output"
        updates_found=true
    fi
else
    append_to_both "No supported package manager found (apt, dnf, yum)."
fi

if [ "$updates_found" = false ] && command -v apt &>/dev/null; then
    append_to_both "System is up-to-date."
elif [ "$updates_found" = false ] && (command -v dnf &>/dev/null || command -v yum &>/dev/null); then
    append_to_both "System is up-to-date."
fi
append_to_both "---------------------------------------"

# Check running services (improved portability)
echo "[+] Checking Top 10 Running Services by Memory Usage..."
append_to_both "Top 10 Running Services by Memory Usage:"
if ps -eo pid,user,%mem,cmd --sort=-%mem &>/dev/null; then
    ps_output=$(ps -eo pid,user,%mem,cmd --sort=-%mem 2>/dev/null | head -n 11)
else
    # Fallback for systems without --sort
    ps_output=$(ps aux 2>/dev/null | head -n 11)
fi
if [ -n "$ps_output" ]; then
    append_command_output "$ps_output"
else
    append_to_both "Could not retrieve process list."
fi
append_to_both "---------------------------------------"

# Save HTML report
generate_html_footer

# Final output
echo ""
echo "Security check complete."
echo "Text report saved to: $report"
echo "HTML report saved to: $html_report"
echo ""
echo "Review the reports before sharing - they may contain sensitive system information."
