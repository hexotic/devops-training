# Kubernetes Notes

## TP7 snippets
```
kubectl create configmap appcolor --from-literal=color=red -o yaml --dry-run=client
```

```sh
kubectl exec -it webapp -- /bin/sh
/opt # export
export APP_COLOR='red'
```
## Network
