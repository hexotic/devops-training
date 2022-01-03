#!/bin/sh

git clone https://github.com/diranetafen/static-website-example.git 
cp static-website-example/index.html index.html.j2

sed -i '28s/Dimension/Dimension : {{ ansible_hostname }}/' index.html.j2

ansible-playbook -i prod.yml webdim.yml
