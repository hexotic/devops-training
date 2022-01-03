#!/bin/sh
sudo pip3 install ansible-lint
ansible-lint nginx.yml
ansible-playbook -i prod.yml nginx.yml
