{ config, ... }:

let
  nixpkgs = import ../../../vendor/nixpkgs;
in

{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
    ../../hardware/holoport-plus
    ../.
  ];

  isoImage.isoBaseName = config.system.build.baseName;
}
