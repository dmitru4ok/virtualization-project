# to be run on ubuntu 22/deb 12

read -sp "VM_PASSWORD: " VM_PASS
echo

# (to be sbstituted with ansible-vault)
# -----
echo "CREDENTIALS REQUIRED FOR creating WEBSERVER VM: "
read -p "OpenNebula login: " WEBSERVER_VM_UNAME
read -sp "OpenNebula password: " WEBSERVER_VM_PASS
echo

echo "CREDENTIALS REQUIRED FOR creating DB VM: "
read -p "OpenNebula login: " DB_VM_UNAME
read -sp "OpenNebula password: " DB_VM_PASS
echo

echo "CREDENTIALS REQUIRED FOR creating CLIENT VM: "
read -p "OpenNebula login: " CLIENT_VM_UNAME
read -sp "OpenNebula password: " CLIENT_VM_PASS
echo

mkdir -p /root/auth
echo "$WEBSERVER_VM_UNAME:$WEBSERVER_VM_PASS" > /root/auth/webserver_auth
echo "$DB_VM_UNAME:$DB_VM_PASS" > /root/auth/db_auth
echo "$CLIENT_VM_UNAME:$CLIENT_VM_PASS" > /root/auth/client_auth
echo ${VM_PASS} > vault-pass.txt
# -------

sudo apt update
UBUNTU_CODENAME=jammy
sudo apt-get -y install gnupg wget apt-transport-https

wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

# onevm
wget -q -O- https://downloads.opennebula.io/repo/repo2.key | gpg --dearmor --yes --output /etc/apt/keyrings/opennebula.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/opennebula.gpg] https://downloads.opennebula.io/repo/6.8/Ubuntu/22.04 stable opennebula" > /etc/apt/sources.list.d/opennebula.list
sudo apt update && sudo apt -y upgrade && sudo apt -y install ansible opennebula-tools python3-pip

# create vms and write prvate ips to /etc/ansible/hosts
sudo ansible-playbook ../ansible/instantiate.yaml

WEBSERVER_PRIVATE_IP=$(awk '/\[webserver\]/ {getline; print}' /etc/ansible/hosts)
DB_PRIVATE_IP=$(awk '/\[db\]/ {getline; print}' /etc/ansible/hosts)
CLIENT_PRIVATE_IP=$(awk '/\[client\]/ {getline; print}' /etc/ansible/hosts)

ansible-vault decrypt ../misc/credentials.yaml --vault-password-file vault-pass.txt
echo "ansible_become_pass: ${VM_PASS}" >> ../misc/credentials.yaml
echo "db_vm_username: ${DB_VM_UNAME}" >> ../misc/credentials.yaml
echo "db_ip: ${DB_PRIVATE_IP}" >> ../misc/credentials.yaml
echo "webserver_vm_username: ${WEBSERVER_VM_UNAME}" >> ../misc/credentials.yaml
echo "webserver_vm_on_pass: ${WEBSERVER_VM_PASS}" >> ../misc/credentials.yaml
echo "client_vm_username: ${CLIENT_VM_UNAME}" >> ../misc/credentials.yaml
ansible-vault encrypt ../misc/credentials.yaml --vault-password-file vault-pass.txt



# sometimes require time even after the instantiation playbook
sleep 15

eval "$(ssh-agent -s)" 
ssh-keygen -t ed25519  -N "" -f ~/.ssh/id_ed25519
ssh-add
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $WEBSERVER_VM_UNAME@$WEBSERVER_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $DB_VM_UNAME@$DB_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $CLIENT_VM_UNAME@$CLIENT_PRIVATE_IP



# can safely execute ansible playbooks here, for example:
# REFACTOR --extra-vars into inventory files (encrypt with vault)
ansible-playbook ../ansible/database.yaml --vault-password-file vault-pass.txt
ansible-playbook ../ansible/webserver.yaml --vault-password-file vault-pass.txt
ansible-playbook ../ansible/client.yaml --vault-password-file vault-pass.txt


ENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2
VMQUERY=$(onevm list --user $WEBSERVER_VM_UNAME --password $WEBSERVER_VM_PASS --endpoint $ENDPOINT | grep webserver-vm)
VMID=$(echo ${VMQUERY} | cut -d ' ' -f 1)
onevm show $VMID --user $WEBSERVER_VM_UNAME --password $WEBSERVER_VM_PASS --endpoint $ENDPOINT > $VMID.txt
PRIV_IP=$(cat ${VMID}.txt | grep PRIVATE\_IP | cut -d '=' -f 2 | tr -d '"')
PUBLIC_IP=$(cat ${VMID}.txt | grep PUBLIC\_IP| cut -d '=' -f 2 | tr -d '"')

PORT=$(cat $VMID.txt | grep TCP_PORT_FORWARDING | cut -d ' ' -f 2 |cut -d ':' -f 1)
ssh -t $CLIENT_VM_UNAME@$CLIENT_PRIVATE_IP "w3m http://${PRIV_IP}:5000"
echo "-----------------------------------------"
echo "WEBAPP DEPLOYED"
echo "ACCESSIBLE AT: http://${PUBLIC_IP}:${PORT}"
echo "-----------------------------------------"

rm vault-pass.txt
rm ${VMID}.txt