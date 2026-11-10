#!/bin/bash
# Prepare le cluster pour le lab Q05. Logs : /var/log/killercoda

# attendre que l'API reponde
until kubectl get nodes >/dev/null 2>&1; do sleep 2; done

kubectl create namespace mariadb

mkdir -p /mnt/data/mariadb

# PV existant, conserve (Retain), sans StorageClass
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
spec:
  capacity:
    storage: 250Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/data/mariadb
YAML

# Manifest du Deployment, sans volume : a completer par le candidat
cat > /root/mariadb-deploy.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
  labels:
    app: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
        - name: mariadb
          image: mariadb:11
          env:
            - name: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD
              value: "1"
          ports:
            - containerPort: 3306
YAML

# Commande "check" : correction detaillee
cat > /usr/local/bin/check <<'CHECK'
#!/bin/bash
NS=mariadb
fail=0
ok()  { echo "  [OK]   $1"; }
ko()  { echo "  [FAIL] $1"; [ -n "$2" ] && echo "         -> $2"; fail=1; }

echo
echo "=== Q05 - PVC + existing PV + Deployment ==="

# 1. PVC
if kubectl get pvc mariadb -n $NS >/dev/null 2>&1; then
  ok "PVC 'mariadb' exists in namespace '$NS'"

  am=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.accessModes[*]}')
  [ "$am" = "ReadWriteOnce" ] && ok "accessModes = ReadWriteOnce" \
    || ko "accessModes = '$am' (expected ReadWriteOnce)"

  sz=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.resources.requests.storage}')
  [ "$sz" = "250Mi" ] && ok "storage request = 250Mi" \
    || ko "storage request = '$sz' (expected 250Mi)"

  ph=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.status.phase}')
  vn=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.volumeName}')
  sc=$(kubectl get pvc mariadb -n $NS -o jsonpath='{.spec.storageClassName}')
  if [ "$ph" = "Bound" ] && [ "$vn" = "mariadb-pv" ]; then
    ok "PVC is Bound to PV 'mariadb-pv'"
  elif [ "$ph" = "Bound" ]; then
    ko "PVC is Bound to '$vn' instead of 'mariadb-pv'" \
       "storageClassName of the PVC is '$sc'. Compare it with the PV (kubectl get pv mariadb-pv -o yaml)"
  else
    ko "PVC is '$ph', not Bound to 'mariadb-pv'" \
       "storageClassName of the PVC is '$sc'. It must match the PV exactly. A PVC spec is immutable: delete and recreate it"
  fi
else
  ko "PVC 'mariadb' not found in namespace '$NS'" "check the name and the namespace"
fi

# 2. PV intact
if kubectl get pv mariadb-pv >/dev/null 2>&1; then
  rp=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
  [ "$rp" = "Retain" ] && ok "PV 'mariadb-pv' still exists with reclaim policy Retain" \
    || ko "PV reclaim policy changed to '$rp'" "the task says not to modify the PV"
else
  ko "PV 'mariadb-pv' no longer exists" "the task says to reuse the existing PV"
fi

# 3. Deployment
if kubectl get deploy mariadb -n $NS >/dev/null 2>&1; then
  ok "Deployment 'mariadb' exists in namespace '$NS'"

  claim=$(kubectl get deploy mariadb -n $NS -o jsonpath='{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}')
  if echo " $claim " | grep -q " mariadb "; then
    ok "Deployment declares a volume using claimName 'mariadb'"
    vname=$(kubectl get deploy mariadb -n $NS -o jsonpath='{.spec.template.spec.volumes[?(@.persistentVolumeClaim.claimName=="mariadb")].name}')
    mp=$(kubectl get deploy mariadb -n $NS -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name==\"$vname\")].mountPath}")
    [ "$mp" = "/var/lib/mysql" ] && ok "volume mounted at /var/lib/mysql" \
      || ko "mountPath = '$mp' (expected /var/lib/mysql)" "volumeMounts goes under the container, and its name must match the volume name"
  else
    ko "Deployment has no volume using the PVC 'mariadb'" "add spec.template.spec.volumes with persistentVolumeClaim.claimName"
  fi

  av=$(kubectl get deploy mariadb -n $NS -o jsonpath='{.status.availableReplicas}')
  [ "$av" = "1" ] && ok "Deployment is available (1/1)" \
    || ko "Deployment is not available yet" "kubectl get pods -n $NS ; kubectl describe pod -n $NS"
else
  ko "Deployment 'mariadb' not found in namespace '$NS'" "apply /root/mariadb-deploy.yaml after editing it"
fi

echo
if [ $fail -eq 0 ]; then
  echo "RESULT: ALL GOOD - click the Check button to finish."
else
  echo "RESULT: not finished yet."
fi
echo
exit $fail
CHECK
chmod +x /usr/local/bin/check

touch /tmp/.lab-ready
