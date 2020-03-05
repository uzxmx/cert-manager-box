# cert-manager-box

This box shows how to use [cert-manager][cert-manager] to manage TLS certificates in
a kubernetes cluster, and [brigade][brigade] to watch for certificate issued events
and renew certificates used outside of kubernetes cluster.

## Quick start

This box uses [kubespray](https://github.com/kubernetes-sigs/kubespray) to deploy a cluster. The
installed kubernetes cluster version is 1.16.7 with below components:

* [calico v3.7.3](https://github.com/projectcalico/calicoctl)
* [helm v3.1.1](https://github.com/helm/helm)

### Setup kubernetes cluster

```
vagrant up --no-provision

# Install dependencies on the host machine.
# Use `sudo` if permission error happens.
pip install -r kubespray/requirements.txt

vagrant provision

# After the above is finished successfully, you can perform below command to connect.
# By default the instance name prefix is `k8s`.
vagrant ssh <instance-name-prefix>-1
```

### Automatically renew certificates

Change directory to `/vagrant`:

```
cd /vagrant
```

Install [cert-manager][cert-manager]:

```
./scripts/install_cert_manager.sh
```

#### For AliDNS

If you own a certificate from AliCloud, install [cert-manager-webhook-alidns][webhook-alidns], update `GROUP_NAME` as your need:

```
GROUP_NAME=example.com ./scripts/install_alidns.sh
```

Then create a cluster issuer for AliDNS, update variable values in the command
as your need:

> The `GROUP_NAME` should be the same as the one above. If you want to apply for
a certificate from letsencrypt production environment, specify `ACME_PRODUCTION=1`
in the environment.

> The `ACME_EMAIL` should be a valid email, otherwise the issuer won't work.

> Use `kubectl get clusterissuer` to see if the issuer is ready.

```
GROUP_NAME=example.com \
  ACME_EMAIL="YOUR_EMAIL" \
  ALIDNS_REGION="" \
  ALIDNS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
  ALIDNS_ACCESS_KEY_SECRET=YOUR_ACCESS_KEY_SECRET \
  ./scripts/create_clusterissuer_alidns.sh
```

Create a SSL certificate for some domain using the above cluster issuer:

> If you want to create a wildcard certificate for your main domain (e.g.
`example.com`), that is to create a certificate for `example.com` and
`*.example.com` (any first-level subdomain), you can sepcify `WILDCARD=1` in the
environment.

> If the above issuer is for letsencrypt production, change `ISSUER_NAME` to
`letsencrypt-alidns`.

```
DOMAIN=YOUR_DOMAIN \
  ISSUER_NAME="letsencrypt-staging-alidns" \
  ./scripts/create_certificate.sh
```

After several minutes, you may notice a new TXT record with a name like
`_acme-challenge.xxxxxx` in AliDNS Console. And after a short while, you will
see a ready certificate by using `kubectl get certificate`. You can use
`kubectl get secret` to get the issued certificate.

As a last step, use below command to verify the certificate:

```
./scripts/verify_certificate.sh YOUR_SECRET_NAME
```

#### For AWS Route53

Create a cluster issuer for Route53, update variable values in the command
as your need:

> The `AWS_ROLE` should be specified in the format like `arn:aws:iam::xxxxxxxxxx`.

> The `ACME_EMAIL` should be a valid email, otherwise the issuer won't work.

> Use `kubectl get clusterissuer` to see if the issuer is ready.

> If you want to apply for a certificate from letsencrypt production environment,
specify `ACME_PRODUCTION=1` in the environment.

```
AWS_REGION="us-east-1" \
  ACME_EMAIL="YOUR_EMAIL" \
  AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID \
  AWS_ACCESS_KEY_SECRET=YOUR_ACCESS_KEY_SECRET \
  AWS_ROLE=YOUR_AWS_ROLE \
  ./scripts/create_clusterissuer_route53.sh
```

Create a SSL certificate for some domain using the above cluster issuer:

> If you want to create a wildcard certificate for your main domain (e.g.
`example.com`), that is to create a certificate for `example.com` and
`*.example.com` (any first-level subdomain), you can sepcify `WILDCARD=1` in the
environment.

> If the above issuer is for letsencrypt production, change `ISSUER_NAME` to
`letsencrypt-route53`.

```
DOMAIN=YOUR_DOMAIN \
  ISSUER_NAME="letsencrypt-staging-route53" \
  ./scripts/create_certificate.sh
```

After several minutes, you may notice a new TXT record with a name like
`_acme-challenge.xxxxxx` in AWS Route53 Console. And after a short while, you will
see a ready certificate by using `kubectl get certificate`. You can use
`kubectl get secret` to get the issued certificate.

As a last step, use below command to verify the certificate:

```
./scripts/verify_certificate.sh YOUR_SECRET_NAME
```

#### Troubleshooting

View cert-manager container log:

```
kubectl -n cert-manager logs -f \
  "$(kubectl -n cert-manager get pods -l app=cert-manager | sed 1d | awk '{print $1}')"
```

### Use brigade to watch for events

Install brigade:

```
./scripts/install_brigade.sh
```

Create a project:

```
brig project create -n brigade
```

> You will need to answer several questions like below. Answer them based on your case. If you use
a private repository, you may want to use git protocol when cloning, then you will need to specify
a path to ssh key which is used to access private repository. Finally, a project ID will be shown.
Keep it because it'll be used in the next step.

> If you use Gitlab CI, there's a `.gitlab-ci.yaml` in the root folder, you can use it
and let brigade worker trigger the Gitlab pipeline.

```
? VCS or no-VCS project? VCS
? Project Name example_group/cert-manager-box
? Full repository name gitlab.example.com/example_group/cert-manager-box
? Clone URL (https://github.com/your/repo.git) git@gitlab.example.com:example_group/cert-manager-box
? Path to SSH key for SSH clone URLs (leave blank to skip) /home/vagrant/.ssh/id_rsa
? Add secrets? No
? Where should the project's shared secret come from? Auto-generate one now
Auto-generated a Shared Secret: "MQUFw2JbuCdCjMZAW2ry9RIw"
? Configure GitHub Access? No
? Configure advanced options No
Project ID: brigade-c1cb1578572318b745c1fdfa6d616f1896092f9cbc65e506ec09a5
```

Install brigade kubernetes gateway, update the project id in the command:

```
PROJECT_ID=YOUR_PROJECT_ID ./scripts/install_brigade_k8s_gateway.sh
```

Check if there is an `Issued` event for a certificate:

```
kubectl describe certificate YOUR_CERTIFICATE_NAME
```

If there is no `Issued` event, generate an event:

```
curl -C- -L -O https://github.com/uzxmx/k8s-busybox/releases/download/v0.1.0/k8s-busybox-v0.1.0-linux-amd64.tar.gz
tar zxf k8s-busybox-v0.1.0-linux-amd64.tar.gz
./linux-amd64/bin/k8s-eventgenerator --name YOUR_CERTIFICATE_NAME --kind Certificate --reason Issued --message 'Fake event'
```

After an `Issued` event is generated, a brigade worker will be launched and `brigade.js`
will be executed. In this way, you can update certificates used outside of kubernetes cluster.

> Use `kubectl -n brigade get pods` to find if there is a brigade worker launched.

> Use `kubectl -n brigade logs -f POD_NAME` to view brigade worker logs.

### Reset kubernetes cluster

```
RESET_CLUSTER=1 vagrant provision
```

[cert-manager]: https://github.com/jetstack/cert-manager
[brigade]: https://github.com/brigadecore/brigade
[webhook-alidns]: https://github.com/uzxmx/cert-manager-webhook-alidns

## License

[MIT License](LICENSE)
