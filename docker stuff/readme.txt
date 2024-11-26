for_db (ubuntu 24.04):
downloads necessary things, creates necessary files and starts a database inside docker container.

for_webserver(debian12lxde):
downloads necessary things, creates necessary files and starts a website (in localhost) inside a docker container. the website is a very basic form where you enter a number and that number gets sent to the database using node.js as api. debian12lxde was used due to the need to view and test the website. Most likely you'd only need to change the installation of docker if youd like to make this work for ubuntu.

note: ive left the IPs and ports as they were (because im not working with creating any machines so im not too fimiliar how to take their info directly from them) so those will need to be changed.
for easier editing: 10.0.1.235 is db-vm and 10.0.0.17 is webserver-vm.
port forwarding: 9357:5432 15571:3000 (on db-vm)
