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
# -------

sudo apt update
UBUNTU_CODENAME=jammy
sudo apt-get -y install gnupg wget apt-transport-https

wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

sudo apt update && sudo apt -y upgrade && sudo apt -y install ansible

sudo apt install python3-pip -y

sudo ansible-playbook ../ansible/instantiate.yaml

WEBSERVER_PRIVATE_IP=$(awk '/\[webserver\]/ {getline; print}' /etc/ansible/hosts)
DB_PRIVATE_IP=$(awk '/\[db\]/ {getline; print}' /etc/ansible/hosts)
CLIENT_PRIVATE_IP=$(awk '/\[client\]/ {getline; print}' /etc/ansible/hosts)


eval "$(ssh-agent -s)" 
ssh-keygen -t ed25519  -N "" -f ~/.ssh/id_ed25519
ssh-add
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no yudm1317@$WEBSERVER_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no yudm1317@$DB_PRIVATE_IP
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no yudm1317@$CLIENT_PRIVATE_IP



# can safely execute ansible playbooks here, for example:
# ansible-playbook webserver.yaml -K 

# but have to tune users for now. Can't do root ping-pong for some reason.
ansible webserver -m ping --extra-vars "ansible_user=$WEBSERVER_VM_UNAME"
ansible client -m ping --extra-vars "ansible_user=$CLIENT_VM_UNAME"
ansible db -m ping --extra-vars "ansible_user=$DB_VM_UNAME"
