let
  # Invoke checking of provided options.
  commonconfig = import <config.nix>;
  pkgs = import <nixpkgs>{};
  lib = pkgs.lib;
  conf = (lib.evalModules {
    modules = [ {imports = [ ./modules/common.nix]; inherit commonconfig; }];
  }).config.commonconfig;

  machine-ace = { config, pkgs, lib, name, resources, nodes, uuid, deploymentName, ... }: lib.recursiveUpdate {
    networking.firewall.allowedTCPPorts = [22 80 443 ];
    common = commonconfig;
    imports = [ ./modules/common.nix ]
      ++ (if commonconfig.instances.ace.targetEnv == "ec2" then 
      [<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>] else []);
    services.traefik = {
      package = pkgs.traefik2;
      enable = true; # {{{
      configOptions = {
        defaultEntrypoints = ["https"];
        logLevel = "DEBUG";
        acme = {
          email = "${config.common.email}";
          entryPoint = "https";
          storage = "/var/lib/traefik/acme.json";
          caServer = config.common.instances.ace.acmeServer;
          httpChallenge.entryPoint = "http";
          domains = [
            { main = "${config.common.instances.ace.hostname}";
            sans = [ "${config.common.instances.ace.hostname}" "${config.common.instances.office.hostname}" ]; }
          ];
        };
        file = {};
        entryPoints.http.address = ":80";
        entryPoints.https = {
          address = ":443";
          tls = {
            minVersion = "VersionTLS12";
            cipherSuites = [ "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256" "TLS_RSA_WITH_AES_256_GCM_SHA384" ];
            sniStrict = true;
            certificates = [{
              certFile = ../secrets/cert.pem;
              keyFile = ../secrets/key.pem;
            }];
            ClientCA = { 
              files = [ ../public/all.pem ];
              optional = false;
            };
          };
        };
        frontends = {
          office = {
            passHostHeader = true;
            entryPoints = [ "https"];
            backend = "office";
            auth.forward.address = "http://127.0.0.1:9000";
            routes.test_1.rule = "Host: ${config.common.instances.ace.hostname},${config.common.instances.office.hostname}";
            passTLSClientCert = { # {{{
              pem = true;
              infos = {
                notBefore = true;
                notAfter = true;
                subject = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
                issuer = {
                  country = true;
                  domainComponent = true;
                  province = true;
                  locality = true;
                  organization = true;
                  commonName = true;
                  serialNumber = true;
                };
              };
            }; # }}}
          };
        };
        backends.office = {
          servers.server1.url = "http://${config.common.instances.office.wg}";
        };
      };
    }; # }}}

    systemd.services = {
      policyengine = { # {{{
        enable = true;
        description = "Rules Engine for ACE";
        wantedBy = [ "multi-user.target" ];
        environment = {
          SSOOFF = "1";
          U2FOFF = "1";
        };
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs.policyengine}/bin/cmd serve -a 127.0.0.1 -p 9000 --opa http://127.0.0.1:9001/v1/data/ap/acl/authorize";
        };
      }; # }}}
      opa = { # {{{
        enable = true;
        description = "Open policy agent";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          ExecStart = "${pkgs.opa}/bin/opa run -s -a 127.0.0.1:9001 -f json ${ ./opa/policy/user_acl_eval } ${ ./opa/records/acls.json} ${./opa/records/users.json}";
        };
      };
    }; # }}}
    environment.systemPackages = with pkgs; [
      policyengine
      opa
    ];
  } commonconfig.instances.ace.extraConfig;

  # ONLYOFFICE machine
  machine-office = { config, pkgs, lib, name, resources, nodes, uuid, deploymentName, ... }: lib.recursiveUpdate {
    common = commonconfig;
    imports = [ ./modules/common.nix ]
      ++ (if commonconfig.instances.office.targetEnv == "ec2" then 
      [<nixpkgs/nixos/modules/virtualisation/amazon-image.nix>] else []);
      
    services.nginx = { # {{{
      enable = true;
      recommendedGzipSettings = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      commonHttpConfig = ''
          log_format  main '$remote_addr - $ssl_client_verify - $ssl_client_s_dn $remote_user "$request" ' '$status "$http_user_agent" "$upstream_response_time"';
          access_log syslog:server=unix:/dev/log main;
          map $http_upgrade $proxy_connection {
            default upgrade;
            "" close;
          }
		  map $http_x_forwarded_proto $the_scheme {
			 default $http_x_forwarded_proto;
			 "" $scheme;
		  }
        '';
      virtualHosts = {
        "${config.common.instances.office.hostname}" = {
          default = true;
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://127.0.0.1:8181/"; 
            extraConfig = ''
			  proxy_set_header X-Forwarded-Proto $the_scheme;
            '';
          };
        };
      };
    }; # }}}

	services.memcached.enable=true;
    services.nextcloud = {
      enable = true;
      hostName = config.common.instances.ace.hostname;
      nginx.enable = true;
      https=true;
	  caching = {
		memcached = true;
	    apcu = true;
	  };
      config = {
        # Username is actually root
        #overwriteProtocol = "https";
        extraTrustedDomains = [
          "${config.common.instances.ace.hostname}"
          "${config.common.instances.office.hostname}"
        ];
      };
    };
    docker-containers.office = {
      image = "onlyoffice/documentserver";
      ports = ["8181:80"];
      extraDockerOptions= [
        "--add-host=${config.common.instances.ace.hostname}:${config.common.instances.office.wg}"
        "--add-host=${config.common.instances.office.hostname}:127.0.0.1"
        #"-v/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
      ];
      
    };
    environment.systemPackages = with pkgs; [
      patchelfUnstable
	  postgresql
      vim tinc_pre wireguard-tools
    ];
  } commonconfig.instances.office.extraConfig;



in {
  ace = machine-ace;
  office = machine-office;

  network.description = "zerotrust-office";
  network.enableRollback = true;

  resources = commonconfig.resources;
  /*
  if commonconfig.targetEnv == "ec2" then {
    ec2SecurityGroups = {
      "matter-sg" = {
        inherit (conf.ec2) region accessKeyId ;
        rules = [
          { typeNumber = -1; codeNumber= -1; protocol="icmp"; sourceIp = "0.0.0.0/0"; }
          { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; }
          { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; }
          { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; }
          { toPort = 443; fromPort = 443; protocol="udp"; sourceIp = "0.0.0.0/0"; }
          { toPort = 51820; fromPort = 51820; protocol="udp"; sourceIp = "0.0.0.0/0"; }
        ];
      };
      */
}

