#!/bin/sh

# nginx on server 1
ansible -i hosts worker01 -b -m apt -a "name=nginx state=present"
ansible -i hosts worker01 -b -m service -a "name=nginx state=started enabled=yes"

# apache on server 2
ansible -i hosts worker02 -b -m apt -a "name=apache2 state=present"
ansible -i hosts worker02 -b -m service -a "name=apache2 state=started enabled=yes"

# Remove nginx on server 1
ansible -i hosts worker01 -b -m apt -a "name=nginx state=absent purge=yes autoremove=yes"

# Remove apache on server 2
ansible -i hosts worker02 -b -m apt -a "name=apache2 state=absent purge=yes autoremove=yes"
