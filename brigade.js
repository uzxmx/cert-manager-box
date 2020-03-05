const { events } = require("brigadier")
const k8s = require("@kubernetes/client-node")
const axios = require("axios")

const kc = new k8s.KubeConfig()
kc.loadFromDefault()

const k8sCoreApi = kc.makeApiClient(k8s.CoreV1Api)
const k8sCustomObjectsApi = kc.makeApiClient(k8s.CustomObjectsApi)

const getCertificate = async (name, namespace) => {
  return await k8sCustomObjectsApi.getNamespacedCustomObject("cert-manager.io", "v1alpha2", namespace, "certificates", name);
}

const getSecret = async (name, namespace) => {
  return await k8sCoreApi.readNamespacedSecret(name, namespace);
}

events.on("Certificate:Issued", (e, p) => {
  let payload = JSON.parse(e.payload)
  let involvedObject = payload.involvedObject
  getCertificate(involvedObject.name, involvedObject.namespace).then(cert => {
    cert = cert.body
    let spec = cert.spec
    let commonName = spec.commonName
    if (commonName.startsWith("*.")) {
      commonName = commonName.substring(2, commonName.length)
    }

    getSecret(spec.secretName, cert.metadata.namespace).then(secret => {
      let data = secret.body.data

      let buf = new Buffer(data["tls.crt"], "base64")
      let certPem = buf.toString("ascii")
      buf = new Buffer(data["tls.key"], "base64")
      let keyPem = buf.toString("ascii")

      console.log("certPem: " + certPem)
      console.log("keyPem: " + keyPem)

      // axios.post('https://gitlab.exaple.com/api/v4/projects/1/trigger/pipeline', {
      //   token: 'YOUR_GITLAB_CI_TOKEN',
      //   ref: 'master',
      //   variables: {
      //     COMMON_NAME: commonName,
      //     TLS_CERT: data['tls.crt'],
      //     TLS_KEY: data['tls.key']
      //   }
      // })
    })
  })
})
