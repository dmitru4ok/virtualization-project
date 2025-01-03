# The ansible-vm part
1. create ubuntu 22.04 vm with 8 GB of disk (ansible-vm)
2. enter into it
3. run: 
```
su # to become root
cd ~ # to go to root's home dir (important!)
apt update
apt -y install git
git clone https://github.com/dmitru4ok/virtualization-project.git
cd virtualization-project/telecomms/shell
chmod +x Main.sh
./Main.sh
```
4. The script will ask you for your vm password (we agreed on it earlier) and OpenNebula credentials.
5. then ansible-vm long updating will start
6. after that, it will create webserver-vm, client-vm, and db-vm without any config. It will also populate hosts file with VM private ips and add ssh keys to the machines

# The client-vm
1.Open VNC in OpenNebula
2.Type 
```
sudo -E weston
```
![image](https://github.com/user-attachments/assets/f134cec0-3356-4fee-9ebc-4aadfe9c0dc3)

2. Click on console

![Screenshot 2024-11-26 205134](https://github.com/user-attachments/assets/7349ed2f-5690-4291-a956-26fa1abff8cd)

3. Type
```
google-chrome-stable --ozone-platform=wayland --no-sandbox

```
4.Enjoy


# The webapp
In virtualization folder (root of the project) create python virtual environment:
```
python3 -m venv .venv
. .venv/bin/activate # to enter it (a little different for Windows, check how-to, pls)
cd telecomms/web
pip install -r requirements.txt 
flask --app app run
```
