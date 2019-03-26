{ revision ? "local", nixpkgs ? <nixpkgs> }:

let
  pkgs = import nixpkgs {};
  systemModule = pkgs.lib.fixMergeModules [ ./modules/common.nix ] {
                   inherit pkgs;
                   utils = {};
                   resources = { };
                   name = "<name>"; uuid = "<uuid>";
                 };

  options = pkgs.lib.filter (opt: opt.visible && !opt.internal)
    (pkgs.lib.optionAttrSetToDocList systemModule.options);

  optionsXML = builtins.toFile "options.xml" (builtins.unsafeDiscardStringContext
    (builtins.toXML options));

  optionsDocBook = pkgs.runCommand "options.html" {
    buildInputs= with pkgs; [libxslt docbook5 docbook5_xsl docbook_xsl_ns libxml2];
} ''
    ${pkgs.libxslt.bin or pkgs.libxslt}/bin/xsltproc \
      --stringparam revision '${revision}' \
      --stringparam program 'nixops' \
      -o temp1 ${nixpkgs + /nixos/doc/manual/options-to-docbook.xsl} ${optionsXML}
    ${pkgs.libxslt.bin or pkgs.libxslt}/bin/xsltproc \
      -o temp2 ${nixpkgs + /nixos/doc/manual/postprocess-option-descriptions.xsl} temp1
    export docbookxsl="http://docbook.sourceforge.net/release/xsl-ns/current"
	export xsltproc="${pkgs.libxslt.bin or pkgs.libxslt}/bin/xsltproc --nonet \
	 --param section.autolabel 1 \
	 --param section.label.includes.component.label 1 \
	 --param html.stylesheet '${pkgs.nixops}/share/doc/nixops/style.css' \
	 --param xref.with.number.and.title 0 \
	 --param toc.section.depth 3 \
	 --param admon.style \"\" \
	 --param callout.graphics.extension '.gif' \
	 --param contrib.inline.enabled 0"
	$xsltproc --xinclude --stringparam profile.condition manual \
	  $docbookxsl/profiling/profile.xsl temp2 \
	  | $xsltproc --output $out $docbookxsl/xhtml/docbook.xsl -
  '';

in optionsDocBook
