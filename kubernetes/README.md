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

## TP 8 snippets
```sh
kubectl get po -n production -o wide
kubectl describe svc -n production app-srv
``
