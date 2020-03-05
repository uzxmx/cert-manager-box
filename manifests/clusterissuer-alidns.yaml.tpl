apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: "$ISSUER_NAME"
spec:
  acme:
    server: "$ACME_SERVER"
    email: "$ACME_EMAIL"
    privateKeySecretRef:
      name: "$ISSUER_NAME"
    solvers:
    - dns01:
        webhook:
          config:
            regionId: "$ALIDNS_REGION"
            accessKeyId: "$ALIDNS_ACCESS_KEY_ID"
            accessKeySecret: "$ALIDNS_ACCESS_KEY_SECRET"
            ttl: 600
          groupName: "$GROUP_NAME"
          solverName: alidns
