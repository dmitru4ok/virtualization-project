# to be run on ubuntu 22

read -sp "Enter the Database Ansible Vault password: " DB_PASS
echo
read -sp "Enter the Client Ansible Vault password: " CLIENT_PASS
echo
read -sp "Enter the Webserver Ansible Vault password: " WS_PASS
echo

DB_VAULT_FILE=$"../misc/db_auth.yaml"
WS_VAULT_FILE=$"../misc/ws_auth.yaml"
CLIENT_VAULT_FILE=$"../misc/client_auth.yaml"

TEMP_DIR="./vault_passwords"
mkdir -p "$TEMP_DIR"

DB_PASS_FILE="$TEMP_DIR/db_pass.txt"
CLIENT_PASS_FILE="$TEMP_DIR/client_pass.txt"
WS_PASS_FILE="$TEMP_DIR/ws_pass.txt"

echo "$DB_PASS" > "$DB_PASS_FILE"
echo "$CLIENT_PASS" > "$CLIENT_PASS_FILE"
echo "$WS_PASS" > "$WS_PASS_FILE"

sudo apt update
UBUNTU_CODENAME=jammy
sudo apt-get -y install gnupg wget apt-transport-https

wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

# onevm
wget -q -O- https://downloads.opennebula.io/repo/repo2.key | gpg --dearmor --yes --output /etc/apt/keyrings/opennebula.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/opennebula.gpg] https://downloads.opennebula.io/repo/6.8/Ubuntu/22.04 stable opennebula" > /etc/apt/sources.list.d/opennebula.list
sudo apt update && sudo apt -y upgrade && sudo apt -y install ansible opennebula-tools python3-pip

# OPENNEBULA accouns usernames for ssh-ing
DB_USER=$(ansible-vault view ../misc/db_auth.yaml --vault-id db@$DB_PASS_FILE | grep "db_user" | awk '{print $2}')
WS_USER=$(ansible-vault view ../misc/ws_auth.yaml --vault-id  ws@$WS_PASS_FILE | grep "ws_user" | awk '{print $2}')
CLIENT_USER=$(ansible-vault view ../misc/client_auth.yaml --vault-id client@$CLIENT_PASS_FILE | grep "client_user" | awk '{print $2}')

# getting sudo passwords
DB_VM_PASSWORD=$(ansible-vault view ../misc/db_auth.yaml --vault-id db@$DB_PASS_FILE | grep "ansible_become_pass" | awk '{print $2}')
WS_VM_PASSWORD=$(ansible-vault view ../misc/ws_auth.yaml --vault-id  ws@$WS_PASS_FILE | grep "ansible_become_pass" | awk '{print $2}')
CLIENT_VM_PASSWORD=$(ansible-vault view ../misc/client_auth.yaml --vault-id client@$CLIENT_PASS_FILE | grep "ansible_become_pass" | awk '{print $2}')

# to list all the vms using opennebula tools
WS_NEBULA_PASSWORD=$(ansible-vault view ../misc/ws_auth.yaml --vault-id ws@$WS_PASS_FILE | grep "ws_password" | awk '{print $2}')


# create vms and write prvate ips to /etc/ansible/hosts
sudo ansible-playbook ../ansible/instantiate.yaml --vault-id ws@$WS_PASS_FILE --vault-id db@$DB_PASS_FILE --vault-id client@$CLIENT_PASS_FILE

WEBSERVER_PRIVATE_IP=$(awk '/\[webserver\]/ {getline; print}' /etc/ansible/hosts)
DB_PRIVATE_IP=$(awk '/\[db\]/ {getline; print}' /etc/ansible/hosts)
CLIENT_PRIVATE_IP=$(awk '/\[client\]/ {getline; print}' /etc/ansible/hosts)

# insert db_private ip into ws_auth credentials
ansible-vault decrypt ../misc/ws_auth.yaml --vault-id ws@$WS_PASS_FILE
echo "db_ip: ${DB_PRIVATE_IP}" >> ../misc/ws_auth.yaml
ansible-vault encrypt ../misc/ws_auth.yaml --vault-id ws@$WS_PASS_FILE

# sometimes require time even after the instantiation playbook
sleep 15

eval "$(ssh-agent -s)"
ssh-keygen -t ed25519  -N "" -f ~/.ssh/id_ed25519
ssh-add
sshpass -p "$WS_VM_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$WS_USER@$WEBSERVER_PRIVATE_IP"
sshpass -p "$DB_VM_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$DB_USER@$DB_PRIVATE_IP"
sshpass -p "$CLIENT_VM_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$CLIENT_USER@$CLIENT_PRIVATE_IP"

# REFACTOR --extra-vars into inventory files (encrypt with vault)
--vault-id client@$CLIENT_PASS_FILE
ansible-playbook ../ansible/database.yaml --vault-id db@$DB_PASS_FILE
ansible-playbook ../ansible/webserver.yaml --vault-id ws@$WS_PASS_FILE
ansible-playbook ../ansible/client.yaml --vault-id client@$CLIENT_PASS_FILE

ENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2
VMQUERY=$(onevm list --user "$WS_USER" --password "$WS_NEBULA_PASSWORD" --endpoint $ENDPOINT | grep webserver-vm)
VMID=$(echo ${VMQUERY} | cut -d ' ' -f 1)
onevm show $VMID --user "$WS_USER" --password "$WS_NEBULA_PASSWORD" --endpoint $ENDPOINT > $VMID.txt
PRIV_IP=$(cat ${VMID}.txt | grep PRIVATE\_IP | cut -d '=' -f 2 | tr -d '"')
PUBLIC_IP=$(cat ${VMID}.txt | grep PUBLIC\_IP| cut -d '=' -f 2 | tr -d '"')

PORT=$(cat $VMID.txt | grep TCP_PORT_FORWARDING | cut -d ' ' -f 2 |cut -d ':' -f 1)
ssh -t $CLIENT_USER@$CLIENT_PRIVATE_IP "w3m http://${PRIV_IP}:5000"
echo "-----------------------------------------"
echo "WEBAPP DEPLOYED"
echo "ACCESSIBLE AT: http://${PUBLIC_IP}:${PORT}"
echo "-----------------------------------------"

rm -rf $TEMP_DIR
rm ${VMID}.txt
