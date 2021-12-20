# k8s-tp6

## Manifest creation & pod launch
```sh
kubectl run webapp --image=kodekloud/webapp-color --port 8080 --env APP_COLOR=red --dry-run=client -o yaml > pod.yaml
kubectl apply -f pod.yaml
kubectl port-forward webapp 8080:8080 --address 0.0.0.0
```

```sh
kubectl create deployment nginx-dp --image nginx:1.21.3 --port 80 --replicas=2
kubectl set image deployment/nginx-dp nginx=nginx:latest

kubectl delete deployment/nginx-dp
```
