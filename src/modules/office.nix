{ config, pkgs, ...} :
{
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
      extraTrustedDomains = with config.common.instances; [
        "${ace.hostname}"
        "${office.hostname}"
      ];
    };
  };

  docker-containers.office = with config.common.instances; {
    image = "onlyoffice/documentserver";
    ports = ["8181:80"];
    extraDockerOptions= [
      "--add-host=${ace.hostname}:${office.wg}"
      "--add-host=${office.hostname}:127.0.0.1"
    ];
  };

  environment.systemPackages = with pkgs; [
    patchelfUnstable
    postgresql
    vim wireguard-tools
  ];
}
