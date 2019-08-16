{ stdenv, cargoToNix, gitignoreSource, runCommand, rustPlatform, holochain-cli }:
{ name, shell ? false, src, zomePath }:

let
  holochain-rust =
    let
      res = builtins.tryEval <holochain-rust>;
    in
    if res.success
      then gitignoreSource <holochain-rust>
      else holochain-cli.src;

  holochain-rust-shell =
    let
      res = builtins.tryEval <holochain-rust>;
    in
    if res.success
      then toString <holochain-rust>
      else holochain-cli.src;

  holochainRust = import holochain-rust {};

  src-with-holochain = runCommand "source" {} ''
    cp -Lr ${src} $out
    chmod +w $out
    ln -s ${holochain-rust} $out/holochain-rust
  '';
in

if shell

then stdenv.mkDerivation {
  name = "build-zome-env";

  nativeBuildInputs = [
    holochainRust.holochain-cli
    holochainRust.holochain-conductor
    rustPlatform.rust.cargo
    rustPlatform.rust.rustc
  ];

  shellHook = ''
    rm -f holochain-rust
    ln -s ${holochain-rust-shell} holochain-rust
  '';
}

else rustPlatform.buildRustPackage {
  inherit name;
  src = src-with-holochain;

  nativeBuildInputs = [
    holochainRust.holochain-cli
  ];

  cargoVendorDir = "vendor";

  # https://github.com/NixOS/nixpkgs/issues/61618
  preConfigure = ''
    export HOME=$(mktemp -d)
  '' + ''
    ln -s ${cargoToNix "${src-with-holochain}/${zomePath}/code"} vendor
  '';

  buildPhase = ''
    mkdir dist
    hc package -o dist/${name}
    cp -r dist $out

    mkdir $out/nix-support
    echo "file binary-dist $out/${name}" > $out/nix-support/hydra-build-products
  '';

  installPhase = ":";
}
