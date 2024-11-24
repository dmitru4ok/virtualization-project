# automate creating ansible vm
# launch this scripton manually creted vm, or your pc if you're brave eough :)

read -p "Input username: " OUSER
read -sp "Input opennebula password: " OPASS
echo

mkdir -p "$HOME/.one"
echo "${OUSER}:${OPASS}" > "$HOME/.one/one_auth"

sudo apt-get update
sudo apt-get -y install gnupg wget apt-transport-https # get packages
# -quiet -Output- to std add - (add PGP key from std)
wget -q -O- https://downloads.opennebula.io/repo/repo2.key | gpg --dearmor --yes --output /etc/apt/keyrings/opennebula.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/opennebula.gpg] https://downloads.opennebula.io/repo/6.8/Ubuntu/22.04 stable opennebula" > /etc/apt/sources.list.d/opennebula.list
sudo apt-get update
sudo apt-get install opennebula-tools -y

RESP=$(onetemplate instantiate 2719 --name ansible-vm --endpoint https://grid5.mif.vu.lt/cloud3/RPC2)
VMID=$(echo $RESP |cut -d ' ' -f 3)
echo $VMID
sleep 30

onevm show $VMID --endpoint https://grid5.mif.vu.lt/cloud3/RPC2 > $VMID.txt

PRIV_IP=$(cat ${VMID}.txt | grep PRIVATE\_IP | cut -d '=' -f 2 | tr -d '"')

echo "ansible-vm private IP: ${PRIV_IP}"
