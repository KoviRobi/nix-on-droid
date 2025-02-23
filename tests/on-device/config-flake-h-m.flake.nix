{
  description = "Nix-on-Droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };

  outputs = { nix-on-droid, ... }: {
    nixOnDroidConfigurations = {
      device = nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [ ./nix-on-droid.nix ];
      };
    };
  };
}
