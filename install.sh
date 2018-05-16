#!/bin/bash

# =======================================================================================
# Setup alias and helper functions
# =======================================================================================
export NEWT_COLORS=''

# Silence
# Use 'command args...'
stfu() {
  "$@" >/dev/null 2>&1
}

# Use 'print_status "text to display"'
print_status() {
    echo
    echo "## $1"
    echo
}

# Use 'echo "Please enter some information: (Default value)"'
#    'variableName=$(inputWithDefault value)'
inputWithDefault() {
    read -r userInput
    userInput=${userInput:-$@}
    echo "$userInput"
}

# Use 'user_in_group user group'
user_in_group() {
    groups $1 | grep -q "\b$2\b"
}
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Run as root
# =======================================================================================
if [[ $(whoami) != "root" ]]; then
    print_status Please run this script as root user.
    exit 1
fi
# ---------------------------------------------------------------------------------------

# =======================================================================================
# 'Switch to Aptitude...'
# =======================================================================================
stfu apt update
stfu apt-get -y install aptitude
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Installing packages required for setup..." \
	--backtitle "Installing OPL Masternode" \
	--title "Installing dependencies..." \
	8 78
# =======================================================================================
stfu aptitude -yq3 update
stfu aptitude -yq3 full-upgrade
stfu aptitude -yq3 install \
	apt-transport-https \
	ca-certificates \
	curl \
	htop \
	fail2ban \
	jq \
	libboost-system-dev \
	libboost-filesystem-dev \
	libboost-chrono-dev \
	libboost-program-options-dev \
	libboost-test-dev \
	libboost-thread-dev \
	libzmq3-dev \
	libminiupnpc-dev \
	libevent-dev \
	lsb-release \
	software-properties-common \
	unattended-upgrades \
	unzip \
	ufw \
	wget

# Add bitcoin repo
stfu add-apt-repository -y ppa:bitcoin/bitcoin
stfu apt update
stfu aptitude -yq3 install \
	libdb4.8-dev \
	libdb4.8++-dev
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Installation variables
# =======================================================================================
rpcuser="opluser"
rpcpassword="$(head -c 32 /dev/urandom | base64)"
rpcport="12548"
opluserpw="$(head -c 32 /dev/urandom | base64)"
publicip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
internalip="$(hostname -I)"
Hostname="$(cat /etc/hostname)"
sshPort=$(cat /etc/ssh/sshd_config | grep Port | awk '{print $2}')
opluser=$(who -m | awk '{print $1;}')
oplwallet=$HOME/.oplcore
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Installing the opl Masternode..." \
	--backtitle "Installing OPL Masternode" \
	--title "Installing the opl Masternode..." \
	8 78
# =======================================================================================
# What you need.
TERM=ansi whiptail --msgbox "You will need:

-A qt wallet with at least 3001 coins
-A Linux server with a static public ip.

This setup is tested on Ubuntu 16.04 64-bit." \
	--backtitle "Installing OPL Masternode" \
	--title "Before you start" \
	24 78

# Step 1
TERM=ansi whiptail --msgbox "Start the qt wallet. Go to Settings→Options→Wallet and check “Show Masternodes Tab” then restart the wallet." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 1" \
	24 78
	
# Step 2
masternodealias=$(TERM=ansi whiptail --inputbox "Create a new receiving address. Open menu File→Receiving addressess… Click the add button and enter a name for the address, for example MN1, then enter it here" \
	--default-item MN1 \
	--backtitle "Installing OPL Masternode" \
	--title "Step 2" \
	--nocancel \
	3>&1 1>&2 2>&3 \
	24 78)
# note:  --default-item is not working here.  need fix.

# Step 3
TERM=ansi whiptail --msgbox "Send exactly 3001 coins to this MN1 address.  Verify that \"Subtract fee from amount\" is NOT checked. Wait for 15 confirmations of this transaction.

Note:  To check the confirmations of the transaction go to Transactions→right Click \"Show Transaction Details\" or Hover over the time clock in the far right of the transaction." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 3" \
	24 78
# Or is it 3000 coins?  Need clarification on the extra coin requirement.

# Step 4
TERM=ansi whiptail --msgbox "Open the debug window via menu Tools→Debug Console." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 4" \
	24 78
	
# Step 5
masternodeprivkey=$(TERM=ansi whiptail --inputbox "Open the debug window via menu Tools→Debug Console and execute the command:

\"masternode genkey\"

This will output your MN priv key, for example:

\"92PPhvRjKd5vIiBcwbVpq3g4CnKVGUEEGrorZJPYYoohgCu9QkF\".

Paste it here then press OK" \
	--backtitle "Installing OPL Masternode" \
	--title "Step 4" \
	--nocancel \
	3>&1 1>&2 2>&3 \
	24 78)

# Step 5
collateral_output_txid=$(TERM=ansi whiptail --inputbox "Execute the command \"masternode outputs\". This will output TX and output pairs of numbers, for example:
\"{
 \"a9b31238d062ccb5f4b1eb6c3041d369cc014f5e6df38d2d303d791acd4302f2\": \"0\"
}\"
Paste just the first number, long number, here and the second number in the next screen." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 5" \
	--nocancel \
	3>&1 1>&2 2>&3 \
	24 78)

# Step 6b
collateral_output_index=$(TERM=ansi whiptail --inputbox "Paste the second, single digit number from the previous step (usually \"0\" here." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 6" \
	--nocancel \
	3>&1 1>&2 2>&3 \
	24 78)

# Step 7
TERM=ansi whiptail --msgbox "Open the masternode.conf file via menu Tools→Open Masternode Configuration File. Without any blank lines type in a space-delimited single line paste the following string:
$masternodealias $publicip:5567 $masternodeprivkey $collateral_output_txid $collateral_output_index" \
	--backtitle "Installing OPL Masternode" \
	--title "Step 7" \
	24 78
	
# Step 8
TERM=ansi whiptail --msgbox "Restart the wallet and go to the “Masternodes” tab. There in the tab “My Masternodes” you should see the entry of your masternode with the status \"MISSING\"." \
	--backtitle "Installing OPL Masternode" \
	--title "Step 8" \
	24 78
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Installing binaries to /usr/local/bin..." \
	--backtitle "Installing OPL Masternode" \
	--title "Install binaries" \
	8 78
# =======================================================================================
oplOS=linux
oplURL=$(curl -s https://api.github.com/repos/opl-coin/opl.coin/releases/latest | jq -r ".assets[] | select(.name | test(\"${oplOS}\")) | .browser_download_url")
oplFilename=$(basename $oplURL)
stfu wget $oplURL
stfu unzip -j $oplFilename -d /usr/local/bin/
stfu chmod +x /usr/local/bin/opl*
stfu rm -rf $oplFilename
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Create wallet directory in users home folder
# =======================================================================================
mkdir $oplwallet
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Creating the opl configuration..." \
	--backtitle "Installing OPL Masternode" \
	--title "Creating configs" \
	8 78
# =======================================================================================
cat <<EOF > $oplwallet/opl.conf
listen=1
server=1
daemon=1
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
logtimestamps=1
maxconnections=256
externalip=$publicip
masternodeprivkey=$masternodeprivkey
masternode=1
EOF
# ---------------------------------------------------------------------------------------

# =======================================================================================
# 'Creating the opl Masternode configuration...'
# =======================================================================================
echo $masternodealias $publicip:$rpcport $masternodeprivkey $collateral_output_txid $collateral_output_index
 > $oplwallet/masternode.conf
# ---------------------------------------------------------------------------------------

# =======================================================================================
# 'Fix wallet permissions...'
# =======================================================================================
stfu chown -R $opluser $oplwallet
stfu chmod 0600 $oplwallet/*
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Installing the opl service..." \
	--backtitle "Installing OPL Masternode" \
	--title "Installing opl service" \
	8 78
# =======================================================================================
cat <<EOF > /etc/systemd/system/opld.service
[Unit]
Description=OPL daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/opld --daemon --conf=$oplwallet/opl.conf -pid=/run/opl/opld.pid
RuntimeDirectory=opld
User=$opluser
Type=forking
WorkingDirectory=$oplwallet
PIDFile=/run/opl/opld.pid
Restart=on-failure

# Hardening measures
####################
# Provide a private /tmp and /var/tmp.
PrivateTmp=true
# Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full
# Disallow the process and all of its children to gain
# new privileges through execve().
NoNewPrivileges=true
# Use a new /dev namespace only populated with API pseudo devices
# such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true
# Deny the creation of writable and executable memory mappings.
MemoryDenyWriteExecute=true

[Install]
WantedBy=multi-user.target
EOF
# ---------------------------------------------------------------------------------------

# =======================================================================================
TERM=ansi whiptail --infobox "Enabling and starting opl service..." \
	--backtitle "Installing OPL Masternode" \
	--title "Enabling service..." \
	8 78
# =======================================================================================
stfu systemctl daemon-reload
stfu systemctl enable opld
stfu systemctl restart opld
# ---------------------------------------------------------------------------------------

# =======================================================================================
# Display logo
# =======================================================================================
cat << EOF                                               
                    .%%%%%#.                   
                 /#%%%%%%%%%%#/                
             /#%%%%%%%%%%%%%%%%%%#.            
          (#%%%%%%%%%%%%%%%%%%%%%%%%#/         
      ,#%%%%%%%%%%%%%%#&%%%%%%%%%%%%%%%%#      
    #%%%%%%%%%%%%%%#       %%%%%%%%%%%%%%#   
    %%%%%%%%%%%#               &%%%%%%%%%%%#   
    %%%%%%%%%                      #%%%%%%%#   
    %%%%%%%%                       %%%%%%%%#   
    %%%%%%%%                       %%%%%%%%#   
    %%%%%%%%                       %%%%%%%%#   
    %%%%%%%%                       %%%%%%%%#   
    %%%%%%%%                       %%%%%%%%#   
    %%%%%%%%                          #%%%%#   
    %%%%%%%#,                            #   
    %%%%%%%%%%#(                               
    %%%%%%%%%%%%%%%/                           
      &%%%%%%%%%%%#                            
          #%%%%%     /#%%#,                    
                  /#%%%%%%%%%/                 
                 #%%%%%%%%%%%%                 
                    #%%%%%#                    
                       &                       
EOF
# ---------------------------------------------------------------------------------------
