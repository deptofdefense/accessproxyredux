# Access Proxy

Access Proxy is a prototype zero-trust/beyondcorp proxy that uses a few opinionated technologies to
 provide a flexible and usable way to authenticate and authorize resource request at the HTTP session
  level.

The project, although now public, is going through an overhaul from the private version we have been using. Our planned work and migration ideas can be found [here][plan]

## What
Access Proxy is the integration and packaging of open source tools in a way that allows minimal
 configurations to bootstrap some elements of a beyondcorp style proxy.

The v1 version of Access Proxy uses:

  - [Traefik v1.7.9](https://traefik.io/)

  - [Open Policy Agent](https://www.openpolicyagent.org/)

  - [Policy Engine](https://github.com/deptofdefense/policyengine)

  - [Vouch Proxy](https://github.com/vouch/vouch-proxy)

  - [Webauthn Demo by Duo](https://github.com/duo-labs/webauthn.io)

  - [NixOS](https://nixos.org/)

  - [Packer](https://www.packer.io/intro/)

## The "So Whats"


### Auth

Authentication and Authorization are key pieces of the zero-trust model. For level setting; authentication is attesting to a user identity and authorization is making decision about what an asserted identity can access at any point in time.

Access Proxy splits those two functions apart and utilizes presented information (certs, etc.) and the resulting data from authentication to do the authorization judgement.

#### Authentication

Authentication in Access Proxy is done with the client presented identity attributes at request time. 
These attributes can include:

  - x509 certificates

  - SSO tokens

  - Webauthn Tokens

Each can be verified by various means by Access Proxy. mTLS is used to validate that an appropriate certificate is being used to access a fronted resource; vouch validates and redirects to an SSO provider, and Webauthn binds a token per sub/domian. 

Of the three pieces, the most important for Access Proxy to handle is mTLS as that is not usually implemented in modern day applications were most of them have SSO hooks where the SSO can do MFA. 

These attributes, and their validation metadata, are passed to the [policy engine](https://github.com/deptofdefense/policyengine) where the attribute tuple is built and evaluated.

#### Authorization -  Policy Engine
The policy engine is currently based on the [Open Policy Engine](https://www.openpolicyagent.org/docs/).

Open Policy Agent uses a datlog like syntax to write rules and uses json to represent data to be evaluated. 

The current attribute tuple is represented as:

```go

type AttributeTuple struct {
	CommonName   string `json:"CommonName`
	SerialNumber string `json:"SerialNumber"`
	Uri          string `json:"Uri"`
	Host         string `json:"Host"`
}

```

And a rule to check if a user exists is written as:

```
authorize = true {
    data.users[_].name = input.CommonName
}
```

The OPA test case for this is:

```
users = [
    {
        "name" :"USER.ADMIN.1",
        "roles": [
            "admin",
            "service1-user",
            "service1-admin"
        ]
    }
]

inputs = [
    {
        "CommonName": "USER.ADMIN.1",
        "Host": "service1",
        "Uri": "/admin"
    }
]

test_host_service1_path_admin {
    authorize with input as inputs[0] with data.users as users 
}
```

### Traefik (ACME, Auth, and Backends)

Traefik is the current proxy of choice as it fullfills our requirements:

 - ACME for server certificates

 - Service Discovery (for future use)

 - Forward Auth mechansism [with client cert data](https://github.com/containous/traefik/pull/4557)

 - Easy to automate config

 - Written in Go (easy to package)

 - Hot swap config/ACME/certs

AccessProxy builds the config at bake time. Below is an example config:

```toml
defaultEntrypoints = ["https"]
logLevel = "DEBUG"

[acme]
caServer = "https://acme-v02.api.letsencrypt.org/directory"
email = "dev@example.com"
entryPoint = "https"
storage = "/var/lib/traefik/acme.json"

[[acme.domains]]
main = "example.com"
sans = ["example.com", "office.example.com"]

[acme.httpChallenge]
entryPoint = "http"

[backends]

[backends.office]

[backends.office.servers]

[backends.office.servers.server1]
url = "http://10.0.0.2"

[entryPoints]

[entryPoints.http]
address = ":80"

[entryPoints.https]
address = ":443"

[entryPoints.https.tls]
cipherSuites = ["TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_RSA_WITH_AES_256_GCM_SHA384"]
minVersion = "VersionTLS12"
sniStrict = true

[entryPoints.https.tls.ClientCA]
files = ["path.pem"]
optional = false

[[entryPoints.https.tls.certificates]]
certFile = "path.crt"
keyFile = "path.key"

[file]

[frontends]

[frontends.office]
backend = "office"
entryPoints = ["https"]
passHostHeader = true

[frontends.office.auth]

[frontends.office.auth.forward]
address = "http://127.0.0.1:9000"

[frontends.office.passTLSClientCert]
pem = true

[frontends.office.passTLSClientCert.infos]
notAfter = true
notBefore = true

[frontends.office.passTLSClientCert.infos.issuer]
commonName = true
country = true
domainComponent = true
locality = true
organization = true
province = true
serialNumber = true

[frontends.office.passTLSClientCert.infos.subject]
commonName = true
country = true
domainComponent = true
locality = true
organization = true
province = true
serialNumber = true

[frontends.office.routes]

[frontends.office.routes.test_1]
rule = "Host: example.com,office.example.com"
```


[plan]: https://github.com/deptofdefense/accessproxyredux/Plan_v2.md