# Kubernetes Notes

## TP7 snippets
```
ubectl create --dry-run=client configmap appcolor --from-literal=color=red -o yaml
```

```sh
kubectl exec -it webapp -- /bin/sh
/opt # export
export APP_COLOR='red'
```
## Network
