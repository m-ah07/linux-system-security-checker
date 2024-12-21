echo "Starting Linux System Security Check..."
echo "---------------------------------------"

# Check for firewall status
echo "[+] Checking Firewall Status..."
if command -v ufw &>/dev/null; then
    ufw status
else
    echo "UFW is not installed."
fi

# Check file permissions
echo "[+] Checking Permissions of Sensitive Files..."
files=("/etc/passwd" "/etc/shadow" "/etc/hosts")
for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        ls -l "$file"
    else
        echo "$file does not exist."
    fi
done

# Check for inactive users
echo "[+] Checking for Inactive Users..."
awk -F: '{ if ($7 != "/bin/false" && $7 != "/usr/sbin/nologin") print $1 }' /etc/passwd

# Check running services
echo "[+] Checking Running Services..."
ps aux --sort=-%mem | head -n 10

# Save report
report="security-report.txt"
echo "Generating security report..."
echo "Security Report - $(date)" > "$report"
echo "---------------------------------------" >> "$report"
echo "Firewall Status:" >> "$report"
if command -v ufw &>/dev/null; then
    ufw status >> "$report"
else
    echo "UFW is not installed." >> "$report"
fi
echo "---------------------------------------" >> "$report"
echo "File Permissions:" >> "$report"
for file in "${files[@]}"; do
    if [ -e "$file" ]; then
        ls -l "$file" >> "$report"
    else
        echo "$file does not exist." >> "$report"
    fi
done
echo "---------------------------------------" >> "$report"
echo "Inactive Users:" >> "$report"
awk -F: '{ if ($7 != "/bin/false" && $7 != "/usr/sbin/nologin") print $1 }' /etc/passwd >> "$report"
echo "---------------------------------------" >> "$report"
echo "Top 10 Running Services by Memory Usage:" >> "$report"
ps aux --sort=-%mem | head -n 10 >> "$report"

echo "Security check complete. Report saved to $report"
