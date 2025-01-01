#!/bin/bash

echo "Starting Enhanced Linux System Security Check..."
echo "================================================"

# Report file
report="security-report.txt"
html_report="security-report.html"

# Function to append a section to the report
append_to_report() {
    echo "$1" >> "$report"
    echo "$1<br>" >> "$html_report"
}

# Generate HTML header
generate_html_header() {
    echo "<!DOCTYPE html><html><head><title>Linux Security Report</title></head><body>" > "$html_report"
    echo "<h1>Linux Security Report - $(date)</h1>" >> "$html_report"
}

# Generate HTML footer
generate_html_footer() {
    echo "</body></html>" >> "$html_report"
}

# Check for firewall status
echo "[+] Checking Firewall Status..."
append_to_report "Firewall Status:"
if command -v ufw &>/dev/null; then
    ufw status >> "$report"
    ufw status | while read -r line; do echo "$line<br>" >> "$html_report"; done
else
    append_to_report "UFW is not installed."
fi
append_to_report "---------------------------------------"

# Check file permissions
echo "[+] Checking Permissions of Sensitive Files..."
files=("/etc/passwd" "/etc/shadow" "/etc/hosts")
append_to_report "File Permissions:"
for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        ls -l "$file" >> "$report"
        ls -l "$file" | while read -r line; do echo "$line<br>" >> "$html_report"; done
    else
        append_to_report "$file does not exist."
    fi
done
append_to_report "---------------------------------------"

# Check for inactive users
echo "[+] Checking for Inactive Users..."
append_to_report "Inactive Users:"
awk -F: '{ if ($7 != "/bin/false" && $7 != "/usr/sbin/nologin") print $1 }' /etc/passwd | tee -a "$report" >> "$html_report"
append_to_report "---------------------------------------"

# Check for updates
echo "[+] Checking for System Updates..."
append_to_report "System Updates:"
if command -v apt &>/dev/null; then
    updates=$(apt list --upgradable 2>/dev/null | tail -n +2)
    if [ -n "$updates" ]; then
        echo "$updates" >> "$report"
        echo "$updates<br>" >> "$html_report"
    else
        append_to_report "System is up-to-date."
    fi
else
    append_to_report "Package manager not supported for update checks."
fi
append_to_report "---------------------------------------"

# Check running services
echo "[+] Checking Top 10 Running Services by Memory Usage..."
append_to_report "Top 10 Running Services by Memory Usage:"
ps aux --sort=-%mem | head -n 10 >> "$report"
ps aux --sort=-%mem | head -n 10 | while read -r line; do echo "$line<br>" >> "$html_report"; done
append_to_report "---------------------------------------"

# Save HTML report
generate_html_footer

# Final output
echo "Security check complete."
echo "Text report saved to $report"
echo "HTML report saved to $html_report"
