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
# Network

Different types:
* `NodePort`
* `ClusterIP`
* `LoadBalancer`

## TP 8 snippets

```sh
kubectl -n production apply -f .
kubectl get po -n production -o wide
kubectl describe svc -n production app-srv
```
## Other commands
Service manifest from command line:
```sh
kubectl create deploy nginx --image nginx --port 80 --replicas=3
kubectl expose deploy/nginx --name nginx-svc --type NodePort --port 80 --dry-run=client -o yaml
kubectl describe svc nginx-svc
# Pay attention to the target port and endpoints
```

# Storage
## Volumes
```yaml
spec:
  volumes:
  - name: data-volume
    hostPath:
      path: /data
      type: Directory  # also DirectoryOrCreate
```

## Persistent volumes
(No imperative command for creation)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
  - ReadWriteOnce    # also possible: ReadOnlyMany, ReadWriteMany
  capacity:
    storage: 1Gi
  awsElasticBlockStore:
    volumeID: <volume-id>
    fsType: ext4
```
