# Lab termine

### Les pieges a retenir

- **StorageClass par defaut** : sans `storageClassName` dans le PVC, la classe par defaut s'applique et le PVC ne se lie pas a un PV sans classe. Ecrire `storageClassName: ""`.
- **Trois champs a faire correspondre** avec le PV : capacite (demande inferieure ou egale), accessModes, storageClassName.
- **Le spec d'un PVC est immuable** : en cas d'erreur, supprimer et recreer.
- **`volumes` au niveau du Pod, `volumeMounts` au niveau du conteneur**, avec le meme `name`.
- **Toujours verifier** : `kubectl get pvc -n <ns>` doit afficher `Bound` et le bon volume, avant de toucher au Deployment.

### Doc

- https://kubernetes.io/docs/tutorials/configuration/configure-persistent-volume-storage/
- https://kubernetes.io/docs/concepts/storage/persistent-volumes/

Pour refaire le lab : relance le scenario, le cluster repart de zero.
