{ buildRubyGem
, ruby
, version ? "1.17.3"
, sha256 ? "0ln3gnk7cls81gwsbxvrmlidsfd78s6b2hzlm4d4a9wbaidzfjxw"}:

buildRubyGem rec {
  inherit ruby;
  name = "${gemName}-${version}";
  gemName = "bundler";
  inherit version;
  source.sha256 = sha256;
  dontPatchShebangs = true;

  postFixup = ''
    sed -i -e "s/activate_bin_path/bin_path/g" $out/bin/bundle
  '';
}
