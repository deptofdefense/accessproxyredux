self: super : {
  # Using updated patchelf
  patchelfUnstable = super.patchelfUnstable.overrideAttrs (old: {
    src = self.fetchFromGitHub {
        owner = "NixOS";
        repo = "patchelf";
		rev = "27ffe8ae871e7a186018d66020ef3f6162c12c69";
		sha256 = "1sfkqsvwqqm2kdgkiddrxni86ilbrdw5my29szz81nj1m2j16asr";
      };
  });
  cloudhsm-client = super.callPackage (
    {stdenv, python, glibc, openssl, json_c, ncurses, libedit, patchelfUnstable, ...}: self.stdenv.mkDerivation rec {
    name = "cloudhsm-client";
    src = super.fetchurl {
      url = https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Xenial/cloudhsm-client_latest_amd64.deb;
      sha256 = "0c2s59c5y3y1qsklv9zphqvjxkq94jb5lnyxb015vgsq9rg40zz0";
    };
    nativeBuildInputs = [ patchelfUnstable ] ;
    buildInputs = [ python openssl json_c glibc.out ncurses libedit ];
    unpackPhase = ''
      ar x $src
      tar xf data.tar.gz
    '';
    buildPhase = ''
      echo Prebuilt libraries from AWS
    '';
    dontStrip = true;
    dontPatchelf = true;
    installPhase = ''

	  mkdir -p $out/bin
      cp -R ./opt/cloudhsm/* $out/.
      pushd opt/cloudhsm/bin
      cp ./* $out/bin/.

      ${patchelfUnstable}/bin/patchelf --debug \
        --set-rpath "${stdenv.lib.makeLibraryPath [glibc.out openssl json_c]}" \
        $out/bin/cloudhsm_client
      ${patchelfUnstable}/bin/patchelf --debug \
        --replace-needed libjson-c.so.2 libjson-c.so.4 \
        $out/bin/cloudhsm_client
      ${patchelfUnstable}/bin/patchelf --debug \
		--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $out/bin/cloudhsm_client

      ${patchelfUnstable}/bin/patchelf --debug \
        --set-rpath "${stdenv.lib.makeLibraryPath [openssl json_c libedit ncurses ]}" \
        $out/bin/cloudhsm_mgmt_util
      ${patchelfUnstable}/bin/patchelf --debug \
        --replace-needed libjson-c.so.2 libjson-c.so.4 \
        --replace-needed libedit.so.2 libedit.so.0.0.58 \
        $out/bin/cloudhsm_mgmt_util
      ${patchelfUnstable}/bin/patchelf --debug \
		--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $out/bin/cloudhsm_mgmt_util

      ${patchelfUnstable}/bin/patchelf --debug \
        --set-rpath "${stdenv.lib.makeLibraryPath [openssl ]}" \
        $out/bin/key_mgmt_util
      ${patchelfUnstable}/bin/patchelf --debug \
        --replace-needed libjson-c.so.2 libjson-c.so.4 \
        --replace-needed libedit.so.2 libedit.so.0.0.58 \
        $out/bin/key_mgmt_util
      ${patchelfUnstable}/bin/patchelf --debug \
		--set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $out/bin/key_mgmt_util

      ldd $out/bin/key_mgmt_util
      popd

    '';

  }){};
  cloudhsm-pkcs11 = super.callPackage (
    {stdenv, openssl, patchelfUnstable, ...}: self.stdenv.mkDerivation rec {
    name = "cloudhsm-client";
    src = super.fetchurl {
      url = https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Xenial/cloudhsm-client-pkcs11_latest_amd64.deb;
      sha256 = "1dw1dp95jjv37rqiwzl5bxvl07gwiwmxq4r8fajil91c82lfmr71";
    };
    nativeBuildInputs = [ stdenv patchelfUnstable ] ;
    unpackPhase = ''
      ar x $src
      tar xf data.tar.gz
    '';
    buildPhase = ''
      echo Prebuilt libraries from AWS
    '';
    dontStrip = true;
    dontPatchelf = true;
    installPhase = ''
	  mkdir -p $out/lib
      pushd opt/cloudhsm/lib
	  ls -alh
	  ldd libcloudhsm_pkcs11_standard.so

      patchelf --debug \
        --replace-needed libcrypto.so.10 libcrypto.so.1.0.0 \
        ./libcloudhsm_pkcs11_standard.so

      patchelf --debug \
        --set-rpath "${stdenv.lib.makeLibraryPath [openssl ]}" \
        ./libcloudhsm_pkcs11_standard.so

	  ldd libcloudhsm_pkcs11_standard.so
      cp ./libcloudhsm_pkcs11_standard.so $out/lib/.
      popd

    '';

  }){};

}
