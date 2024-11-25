# to be run on ubuntu 22/deb 12

read -sp "Ansible-vault password: " VAULT_PASS
echo
echo ${VAULT_PASS} > vault-pass.txt


sudo apt update
UBUNTU_CODENAME=jammy
sudo apt-get -y install gnupg wget apt-transport-https

wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

sudo apt update && sudo apt -y upgrade && sudo apt -y install ansible

sudo apt install python3-pip -y

sudo ansible-playbook ../ansible/instantiate.yaml --vault-password-file vault-pass.txt
rm vault-pass.txt
