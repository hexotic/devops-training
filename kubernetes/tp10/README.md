# TP 10 - Ingress

## Commands

```sh
# Enable and start ingress module:
minikube addons enable ingress

# Fake domain for ingress:
sudo sh -c 'echo www.chris-webapp.com >> /etc/hosts

# Launch pods and services
kubectl apply -f .

# Check ingress:
curl www.chris-webapp.com/red:8080
curl www.chris-webapp.com/blue:8080
```
