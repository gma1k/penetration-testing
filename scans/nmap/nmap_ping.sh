#!/bin/bash

scan_host() {
  nmap -sn $1 > /dev/null
  if [ $? -eq 0 ]; then
    echo "$1 is up"
  fi
}

scan_range() {
  for i in $(seq $1 $2); do
    scan_host $3.$i
  done
}

calculate_range() {
  # Convert the IP address to binary format
  ip_bin=$(echo "$1" | awk -F. '{printf "%08d%08d%08d%08d\n", strtonum("0b" $1), strtonum("0b" $2), strtonum("0b" $3), strtonum("0b" $4)}')
  
  # Calculate the network prefix and suffix from the subnet mask
  prefix=${ip_bin:0:$2}
  suffix=${ip_bin:$2}
  
  # Calculate the first and last host addresses in binary format by flipping the suffix bits to zero and one respectively
  first_host_bin=$prefix$(printf "%0${#suffix}d\n" | tr '0' '1')
  last_host_bin=$prefix$(printf "%0${#suffix}d\n" | tr '0' '1')
  
  # Convert the first and last host addresses to decimal format and return them as an array
  first_host_dec=$(echo "$first_host_bin" | awk '{print strtonum("0b" substr($0,1,8)) "." strtonum("0b" substr($0,9,8)) "." strtonum("0b" substr($0,17,8)) "." strtonum("0b" substr($0,25,8))}')
  
  last_host_dec=$(echo "$last_host_bin" | awk '{print strtonum("0b" substr($0,1,8)) "." strtonum("0b" substr($0,9,8)) "." strtonum("0b" substr($0,17,8)) "." strtonum("0b" substr($0,25,8))}')
  
  echo "$first_host_dec $last_host_dec"
}

# You can change eth0 to any other interface name that you want to use
ip_address=$(ip -o -f inet addr show eth0 | awk '{print $4}' | cut -d/ -f1)
subnet_mask=$(ip -o -f inet addr show eth0 | awk '{print $4}' | cut -d/ -f2)

# Calculate the range of hosts from the IP address and subnet mask using an array variable 
range=($(calculate_range $ip_address $subnet_mask))

# Extract the start and end of the range from the array variable 
start=${range[0]##*.}
end=${range[1]##*.}

# Extract the network prefix from the IP address
network=${ip_address%.*}.

scan_range $start $end $network

datetime=$(date +"%Y-%m-%d_%H-%M-%S")

file_name="ping_scan_results_$datetime.txt"

scan_range $start $end * > $file_name

mail -s "Ping scan completed on $datetime" -a $file_name user@example.com < /dev/null
