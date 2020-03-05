apiVersion: v1
kind: Secret
metadata:
  name: route53-secret
  namespace: cert-manager
type: Opaque
data:
  key: "$(echo $AWS_ACCESS_KEY_SECRET | base64)"

---
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
        route53:
          region: "$AWS_REGION"
          accessKeyID: "$AWS_ACCESS_KEY_ID"
          secretAccessKeySecretRef:
            name: route53-secret
            key: key
          role: "$AWS_ROLE"
