### Task

A MariaDB Deployment in the `mariadb` namespace was deleted by mistake. Its PersistentVolume was retained and must be reused.

1. A PersistentVolume already exists. Find it and inspect it. **Do not modify it.**
2. Create a PersistentVolumeClaim named `mariadb` in the `mariadb` namespace:
   - access mode `ReadWriteOnce`
   - storage request `250Mi`
   - it must bind to the existing PV
3. Edit the Deployment manifest `/root/mariadb-deploy.yaml` so that it uses the PVC, mounted at `/var/lib/mysql`.
4. Apply the manifest and make sure the Deployment is running.

<details><summary>Traduction francaise</summary>

Un Deployment MariaDB du namespace `mariadb` a ete supprime par erreur. Son PersistentVolume a ete conserve et doit etre reutilise.

1. Un PV existe deja. Trouve-le et inspecte-le. **Ne le modifie pas.**
2. Cree un PVC nomme `mariadb` dans le namespace `mariadb` : mode d'acces `ReadWriteOnce`, demande de `250Mi`, et il doit se lier au PV existant.
3. Modifie le manifest `/root/mariadb-deploy.yaml` pour qu'il utilise le PVC, monte sur `/var/lib/mysql`.
4. Applique le manifest et verifie que le Deployment tourne.

</details>

<br>

Tape `check` dans le terminal pour voir ou tu en es.

<br>

<details><summary>Indice 1 : par ou commencer</summary>

Regarde d'abord ce qui existe. Trois champs du PV doivent correspondre a ton PVC : la capacite, le mode d'acces et la StorageClass.

```plain
kubectl get pv
kubectl get pv mariadb-pv -o yaml
kubectl get storageclass
```{{exec}}

</details>

<details><summary>Indice 2 : le PVC reste Pending ou se lie au mauvais volume</summary>

Le cluster a une StorageClass **par defaut**. Si ton PVC n'indique pas `storageClassName`, il recoit cette classe par defaut et ne se liera jamais au PV existant, qui lui n'a pas de classe.

Il faut ecrire explicitement `storageClassName: ""` dans le PVC.

Le spec d'un PVC est immuable : s'il est faux, supprime-le et recree-le.

</details>

<details><summary>Indice 3 : ou placer le volume dans le Deployment</summary>

Deux blocs, a deux niveaux differents :

- `volumes:` au niveau de `spec.template.spec` (meme niveau que `containers:`)
- `volumeMounts:` dans le conteneur (meme niveau que `image:`)

Le `name` doit etre identique dans les deux blocs.

</details>

<details><summary>Ou chercher dans la doc</summary>

- Mots-cles : `Configure a Pod to Use a PersistentVolume for Storage`
  https://kubernetes.io/docs/tutorials/configuration/configure-persistent-volume-storage/
- Mots-cles : `Persistent Volumes`
  https://kubernetes.io/docs/concepts/storage/persistent-volumes/

</details>

<details><summary>Solution complete</summary>

Le PVC :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
```

```plain
kubectl apply -f pvc.yaml
kubectl get pvc -n mariadb
```

Dans `/root/mariadb-deploy.yaml`, ajoute sous le conteneur :

```yaml
          volumeMounts:
            - name: mariadb-data
              mountPath: /var/lib/mysql
```

et au niveau de `spec.template.spec` (aligne avec `containers:`) :

```yaml
      volumes:
        - name: mariadb-data
          persistentVolumeClaim:
            claimName: mariadb
```

```plain
kubectl apply -f /root/mariadb-deploy.yaml
kubectl rollout status deploy/mariadb -n mariadb
check
```

</details>
