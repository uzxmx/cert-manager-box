apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: "$NAME"
spec:
  # By default \`renewBefore\` is 720h, that is 30 days.
  renewBefore: 960h
  secretName: "$SECRET_NAME"
  # commonName: "*.kangyu.info"
  commonName: "$(sh -c "([ -z '$WILDCARD' ] && echo $DOMAIN) || echo '*.$DOMAIN'")"
  dnsNames:
  - "$DOMAIN"
$(sh -c "
  if [ -n '$WILDCARD' ]; then
  echo '\
  - *.$DOMAIN
'
  fi
")
  issuerRef:
    name: "$ISSUER_NAME"
    kind: ClusterIssuer
