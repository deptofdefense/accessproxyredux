{
  resources = {
    output.wg_key_office.script = ''
      wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
      jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
    '';
    output.wg_key_ace.script = ''
      wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
      jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
    '';
  };
  instances = {
    ace = {
      hostname = "cloud.example.com";
      targetEnv = "virtualbox";
      wg = "10.0.0.1";
      extraConfig = {
        users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
      };
    };
    office = {
      hostname = "office.cloud.example.com";
      targetEnv = "virtualbox";
      wg = "10.0.0.2";
      extraConfig = {
        services.nextcloud.config.adminpass = "SOMEPASSWORD";
        users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
      };
    };
  };
}
