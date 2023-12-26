#!/bin/bash

password_file=/path/to/file
USER=user_account

start_time=$(date +%s)

# Print header
echo -e "Hostname\tMount-Point\tFilesystem\tFS-Type\tUsage" >> /tmp/file_system_out.txt

# Initialize variable to store the last known hostname
last_hostname=""

# Loop through hosts
for i in $(cat corp_host); do
    vm_name=$(sshpass -f '$password_file' ssh -o StrictHostKeyChecking=no -q USER@$i "hostname -s")
    output=$(sshpass -f '$password_file' ssh -o StrictHostKeyChecking=no -q USER@$i "sudo df -hT | awk '\$6 > 70 && !/\/var\/lib/ && !/\/run/ {print \"$vm_name\t\" \$7 \"\t\" \$1 \"\t\" \$2 \"\t\" \$6}' | grep -v 'Mounted'")
# output=$(sshpass -f /home/CORP.hitachi-powergrids.com/adm-pancabh/mine_corp ssh -o StrictHostKeyChecking=no -q USER@$i "sudo df -Th | awk -v vm_name=\"$vm_name\" '\$6 > 70 && \$7 !~ /var\/lib/ && $7 !~ /run/ {print vm_name "\t" $7 "\t" $1 "\t" $2 "\t" $6}' | grep -v 'Mounted'")

    # If the hostname is missing, use the last known hostname
    if [ -z "$vm_name" ]; then
        vm_name="$last_hostname"
    else
        last_hostname="$vm_name"
    fi

    # Print output in a systematic way
    echo -e "$output" | grep -E '[7-9][0-9]\%'
#done
done >> /tmp/file_system_out.txt

cat /tmp/file_system_out.txt | awk '{print $2}' | sort | uniq -c >> out.txt

echo -e "Hi team,\nCSV generated report for LINUX Filesystem above than 70%." >> email_body.txt
echo -e "\n\nVM_count\tFile_system" >> email_body.txt
echo -e "_____________________"  >> email_body.txt
echo -e "`cat out.txt | awk '{print $1 "\t" $2 "\t"}' | sort -n`" >> email_body.txt
echo -e "\n\n With Regards," >> email_body.txt
echo -e "AP" >> email_body.txt

awk 'BEGIN {OFS = ","} {print $1, $2, $3, $4, $5}' /tmp/file_system_out.txt > /tmp/file_system_out.csv
echo "$(cat email_body.txt)" | mailx -vv -a /tmp/file_system_out.csv -r sender_address -s "FS CSV FILE" -S smtp="SMTP_SERVER_IP" recipeint_address

rm -f /tmp/file_system_out.* out.txt email_body.txt

end_time=$(date +%s)
time_diff=$((end_time - start_time))
total_time=$((time_diff / 60))
echo "Time taken by full script to get executed is: $total_time minutes"