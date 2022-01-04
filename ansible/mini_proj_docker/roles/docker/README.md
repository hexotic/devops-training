# Ansible Role: docker

Supported distributions:
* ubuntu
* centos

This role installs docker and docker_container ansible module.


# Example playbook
```yaml
- hosts: prod
  become: true
  roles:
    - docker
```
