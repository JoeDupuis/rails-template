{ project_dir ? (toString ./.)
, pkgs ? import <nixpkgs> {
  overlays = [(self: super: {
    inherit (self.callPackage ./nix/ruby {
      inherit (self.darwin) libiconv libobjc libunwind;
      inherit (self.darwin.apple_sdk.frameworks) Foundation;
    })
      ruby_2_5
      ruby_2_6
      ruby_2_7;

    bundler  = self.callPackage ./nix/bundler { sha256 = "1sjnfsyw80g56kj96gdfgxfb793h6d5fyyir4zf2x71wk4wq1qy7";
                                                version = "2.0.1";
                                                ruby = self.ruby_2_7;};
  })];
}
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Uses the overlaid bundler...
    bundler
    # ... and the ruby it's been configured to use.
    bundler.ruby

    # nokogiri
    zlib

    # postgresql, only used for the client
    postgresql_11

    # Node JS dependencies, used to compile the JS parts.
    nodejs-10_x
    yarn

    #to boot the db and services vm
    nixops
  ];
}
