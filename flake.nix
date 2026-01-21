{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    agenix.url = "github:ryantm/agenix";
    comin.url = "github:nlewo/comin";
  };

  outputs = { self, nixpkgs, agenix, comin, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;

    mkHost = name:
      lib.nameValuePair name
        (lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${name}/configuration.nix
            agenix.nixosModules.default
            comin.nixosModules.comin
          ];
        });

    hosts =
      builtins.filter
        (name: builtins.pathExists ./hosts/${name}/configuration.nix)
        (builtins.attrNames (builtins.readDir ./hosts));
  in
  {
    nixosConfigurations =
      lib.listToAttrs (map mkHost hosts);
  };
}
