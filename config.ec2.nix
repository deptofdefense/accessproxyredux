rec {
  resources = {
    output.wg_key_office.script = ''
      wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
      jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
    '';
    output.wg_key_ace.script = ''
      wg genkey | tr -d '\n' | tee $out/privatekey | wg pubkey | tr -d '\n' > $out/publickey
      jq '{pub:$pub,priv:$priv}' --null-input --rawfile pub $out/publickey --rawfile priv $out/privatekey
    '';
    ec2SecurityGroups = {
      "office-sg" = {
        region = "us-gov-east-1";
        accessKeyId = "SOMEKEY";
        rules = [
          { typeNumber = -1; codeNumber= -1; protocol="icmp"; sourceIp = "0.0.0.0/0"; }
          { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; }
          { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; }
          { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; }
          { toPort = 443; fromPort = 443; protocol="udp"; sourceIp = "0.0.0.0/0"; }
          { toPort = 51820; fromPort = 51820; protocol="udp"; sourceIp = "0.0.0.0/0"; }
        ];
      };
    };
  };
  instances = {
    ace = {
      hostname = "ace.example.com";
      targetEnv = "ec2";
      wg = "10.0.0.1";
      ec2 = {
        region = "us-gov-east-1";
        zone = "us-gov-east-1a";
        ami = "ami-0a0921b08375ce59f";
        accessKeyId = "SOMEKEY";
        keyPair = "SOMEKEYPAIR";
      };
      extraConfig = {
        users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
      };
    };
    office = {
      hostname = "office.ace.example.com";
      targetEnv = "ec2";
      wg = "10.0.0.2";
      ec2 = {
        region = "us-gov-east-1";
        zone = "us-gov-east-1a";
        ami = "ami-0a0921b08375ce59f";
        accessKeyId = "SOMEKEY";
        keyPair = "SOMEEC2KEYPAIR";
      };
      extraConfig = {
        services.nextcloud.config.adminpass = "SOMEPASSWORD";
        users.users.root.openssh.authorizedKeys = { keyFiles = [ /home/SOMEUSER/.ssh/id_ecdsa.pub ]; };
      };
    };
  };
}
