# to be run on ubuntu 22/deb 12

read -sp "VM_PASSWORD: " VM_PASS
echo

# (to be sbstituted with ansible-vault)
# -----

echo "CREDENTIALS REQUIRED FOR creating CLIENT VM: "
read -p "OpenNebula login: " CLIENT_VM_UNAME
read -sp "OpenNebula password: " CLIENT_VM_PASS
echo

mkdir -p /root/auth
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

CLIENT_PRIVATE_IP=$(awk '/\[client\]/ {getline; print}' /etc/ansible/hosts)

# sometimes require time even after the instantiation playbook
sleep 15

eval "$(ssh-agent -s)" 
ssh-keygen -t ed25519  -N "" -f ~/.ssh/id_ed25519
ssh-add
sshpass -p $VM_PASS ssh-copy-id -o StrictHostKeyChecking=no $CLIENT_VM_UNAME@$CLIENT_PRIVATE_IP

ansible-playbook ../ansible/client.yaml --extra-vars "ansible_become_pass=$VM_PASS ansible_user=$CLIENT_VM_UNAME"
