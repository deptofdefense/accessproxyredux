## ACE in Nix

### Why this is awesome

1. Reproducible server in various forms. Update at will. Kill it all and regenerate.
2. Like Terraform: manages VPC, subnets, elasticIP (unused for now), route tables, security groups, etc.
3. Updates are transactional and allows for rollback.
4. ACME/Let's Encrypt for server-side SSL certificates

TODO:
- [ ] [Fail2ban](https://github.com/fail2ban/fail2ban) to quiet the noise of the internet
- [ ] CRL/OCSP/etc.
- [ ] Show how to update Nixpkgs and certs.
- [ ] Remove bootstrap certs

### Using
Requirements:

1. [nix](https://nixos.org/nix/download.html)
2. GNU Make
3. Wireguard-utils
4. `public/all.pem` of trusted root CAs for clients
5. `secrets/cert.pem` default cert used for testing and fallback
6. `secrets/key.pem` default cert used for testing and fallback

Buiding the machines is easiest on a Linux machine. If on OSX, easiest is to use a remote builder, but this is not recommended without some Nix experience.  Information available [here](https://github.com/LnL7/nix-docker).  If you have docker:
```bash
source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)
```

#### Deployment to "local" virtualbox
This creates a directory `local` containing a statefile and config.
```bash
make local create
cp config.virtualbox.nix local/config.nix
make local deploy
```

#### SSH into machines using ssh-agent
```bash
make local ssh ace
```

#### Update
```bash
make local deploy
```

#### Documents
``` bash
make doc
```

### ONLYOFFICE setup

Modify this as needed. Defaults can be modified in DEPLOYMENT/config.nix

1. Login as root/SOMEPASSWORD
2. Top-right user icon -> "+ App" -> "Office & Text" -> Add ONLYOFFICE app
3. Top-right user icon -> "Settings" -> "ONLYOFFICE"
4. Document Editing Service: https://office.cloud.example.com/
5. Advanced -> Internal Document Editing Service: http://office.cloud.example.com/
6. Advanced -> Internal Server: http://cloud.example.com/
