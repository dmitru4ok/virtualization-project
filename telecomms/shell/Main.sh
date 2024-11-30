# to be run on ubuntu 22

read -sp "VM sudo password: " VM_PASS
echo

read -sp "Ansible-vault password for webserver user: " WEBSERVER_ANS_PASS
echo

read -sp "Ansible-vault password for databse user: " DB_ANS_PASS
echo

read -sp "Ansible-vault password for client user: " CLIENT_ANS_PASS
echo

echo $WEBSERVER_ANS_PASS > webserver_vault_auth.txt
echo $DB_ANS_PASS > db_vault_auth.txt
echo $CLIENT_ANS_PASS > client_vault_auth.txt
echo $VM_PASS > vm-sudo-pass.txt

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
ansible-playbook ../ansible/instantiate.yaml --vault-id ws@webserver_vault_auth.txt --vault-id db@db_vault_auth.txt --vault-id client@client_vault_auth.txt

# for setting up passwordless ssh
echo "Extracting OpenNebula logins credentials into Main.sh"
WEBSERVER_VM_UNAME=$(ansible-vault view ../misc/ON_webserver.yaml --vault-id ws@webserver_vault_auth.txt | grep webserver_vm_username | cut -d ":" -f 2 | tr -d " ")
DB_VM_UNAME=$(ansible-vault view ../misc/ON_db.yaml --vault-id db@db_vault_auth.txt | grep db_vm_username | cut -d ":" -f 2 | tr -d " ")
CLIENT_VM_UNAME=$(ansible-vault view ../misc/ON_client.yaml --vault-id client@client_vault_auth.txt | grep client_vm_username | cut -d ":" -f 2 | tr -d " ")

WEBSERVER_PRIVATE_IP=$(awk '/\[webserver\]/ {getline; print}' /etc/ansible/hosts)
DB_PRIVATE_IP=$(awk '/\[db\]/ {getline; print}' /etc/ansible/hosts)
CLIENT_PRIVATE_IP=$(awk '/\[client\]/ {getline; print}' /etc/ansible/hosts)


# for creating Opennebula client on the backend
WEBSERVER_VM_PASS=$(ansible-vault view ../misc/ON_webserver.yaml --vault-id ws@webserver_vault_auth.txt | grep webserver_vm_password | cut -d ":" -f 2 | tr -d " ")

# sometimes require time even after the state is "present" in the playbook
sleep 15

eval "$(ssh-agent -s)" 
ssh-keygen -t ed25519  -N "" -f ~/.ssh/id_ed25519
ssh-add
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $WEBSERVER_VM_UNAME@$WEBSERVER_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $DB_VM_UNAME@$DB_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $CLIENT_VM_UNAME@$CLIENT_PRIVATE_IP


ansible-playbook ../ansible/database.yaml --vault-id db@db_vault_auth.txt --extra-vars="ansible_become_pass=$VM_PASS"
ansible-playbook ../ansible/webserver.yaml --vault-id ws@webserver_vault_auth.txt --vault-id db@db_vault_auth.txt --extra-vars="ansible_become_pass=$VM_PASS db_ip=$DB_PRIVATE_IP"
ansible-playbook ../ansible/client.yaml --vault-id client@client_vault_auth.txt --extra-vars="ansible_become_pass=$VM_PASS"


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

rm *.txt