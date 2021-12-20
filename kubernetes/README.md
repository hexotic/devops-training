# Kubernetes Notes

## TP7 snippets
```
kubectl create configmap appcolor --from-literal=color=red
kubectl get configmaps/appcolor -o yaml
```

```sh
kubectl exec -it webapp -- /bin/sh
/opt # export
export APP_COLOR='red'
```
## Network
