# AWS WIP

# Codedeploy
Role: resource access with autorization

codecommit -> codebuild -> S3 -> codedeploy (use S3)
Codebuild requires some roles to interact with other AWS components

EC2 needs:
* CodeDeploy agent
* CodeDeploy role
* S3 role

Beware of roles

Must add `appspec.yml` to repo for CodeDeploy

1. CodeCommit
2. Build + test + dopckerHub
3. packaging and push to S3
4. Configure CodeDeploy (Machines, deployment strategy, S3)
5. Configure CodeDeploy agents
6. Agents connect to CodeDeploy
7. And get info for tasks
8. Agents get S3 code
9. Deploy according to tasks

## Application configuration
Compute platform: EC2/On-premises
Service role: codedeploy, s3
Deployment type: in place OR Blue/Green
Deployment Configuration: choose opt
(Require versioning on S3)

Install agent codedeploy.txt
`Script for EC2`
```sh
#!/bin/bash
#installer l'agent codedeploy
#https://docs.aws.amazon.com/fr_fr/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html
sudo apt-get update -y	
sudo apt install ruby-full -y
sudo apt-get install wget -y
cd /home/ubuntu
#wget https://bucket-name.s3.region-identifier.amazonaws.com/latest/install
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo ./install auto > /tmp/logfile
sudo service codedeploy-agent status
sudo service codedeploy-agent start
sudo service codedeploy-agent status
```

S3
* frazer-codedeploy-youtube-lab
activer versioning
put S3 in public access

CodeDeploy
Create app: frazer-youtube-lab
Deployment group: EC2, name frazer-production
Role: create role: service type: CodeDeploy
Select use case: CodeDeploy
Role name: frazer-codeploy-youtube
Choose created role
Deploy: in place

Env cfg:
Select EC2 instances (the one created)
Key: app value: codedeploy

Deployment parameter: CodeDeployDefault.AllAtOnce
Click create deployment group

`appspec.yml`
```sh
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ubuntu/webapp
hooks:
  BeforeInstall:
    - location: scripts/install_docker.sh
      timeout: 300
      runas: root

  ApplicationStart:
    - location: scripts/webapp.sh
      timeout: 300
      runas: root
  
  ValidateService:
    - location: scripts/validate_application.sh
      timeout: 300
```

