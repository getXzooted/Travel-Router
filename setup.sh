#!/bin/bash

set -e


# --- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}##################################################${NC}"
echo -e "${GREEN}#     SECURE TRAVEL GATEWAY PROVISIONER          #${NC}"
echo -e "${GREEN}##################################################${NC}"


# 1. AUTO-COPY CONFIG
if [ ! -f "config.yml" ]; then
    echo -e "${YELLOW}[!] 'config.yml' not found. Creating it from template...${NC}"
    cp config.example.yml config.yml
else
    echo -e "${GREEN}[+] 'config.yml' found.${NC}"
fi


# 2. VALIDATION CHECK (The "Stop" Logic)
# We grep for the placeholder text "REPLACE_ME" in the user's config file.
if grep -q "REPLACE_ME" config.yml; then
    echo ""
    echo -e "${RED}[X] ACTION REQUIRED: CONFIGURATION NEEDED${NC}"
    echo -e "${YELLOW}You must edit the configuration file with your specific keys and IPs.${NC}"
    echo ""
    echo -e "Run this command to edit:"
    echo -e "${GREEN}nano $(pwd)/config.yml${NC}"
    echo ""
    echo "Once you have saved your changes, run this script again."
    exit 1
fi


# 3. VALIDATION CHECK: KEY FORMAT (New Feature)
# Extracts the server public key from config to check format
SERVER_PUBKEY=$(grep "vpn_server_pubkey:" config.yml | awk '{print $2}' | tr -d '"')

# Regex check for Base64 (approx 44 chars, ends in =)
if [[ ! "$SERVER_PUBKEY" =~ ^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$ ]]; then
    echo ""
    echo -e "${RED}[X] ERROR: INVALID PUBLIC KEY FORMAT${NC}"
    echo -e "The 'vpn_server_pubkey' in config.yml is invalid."
    echo -e "Current value: ${YELLOW}$SERVER_PUBKEY${NC}"
    echo -e "It must be a Base64 WireGuard key (e.g., 'AbCdEfGhIjKlMnOpQrStUvWxYz1234567890=')."
    echo -e "If you are just testing, generate a dummy key with: ${GREEN}wg genkey | wg pubkey${NC}"
    exit 1
fi


# 4. INSTALL ANSIBLE (If missing)
if ! command -v ansible >/dev/null; then
    echo -e "${YELLOW}[!] Ansible is not installed. Installing now...${NC}"
    sudo apt update
    sudo apt install -y ansible
fi


# 5. RUN PLAYBOOK
echo -e "${GREEN}[+] Configuration valid. Launching Ansible...${NC}"
ansible-playbook playbook.yml


