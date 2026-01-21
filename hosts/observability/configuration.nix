{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./alertmanager.nix
    ./prometheus.nix
    ./grafana.nix
  ];
  nix.settings = {
    sandbox = false;
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };
  services.fstrim.enable = false; # Let Proxmox host handle fstrim
  networking.firewall = {
    allowedTCPPorts = [
      9090
      9093
      3000
    ];
  };
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };
  # Cache DNS lookups to improve performance
  services.resolved = {
    extraConfig = ''
      Cache=true
      CacheFromLocalhost=true
    '';
  };
  # Install basic system utilities
  environment.systemPackages = with pkgs; [
    vim-full
    htop
    git
  ];
  # AGE
  age.secrets = {
    authentik-oauth-client-secret = {
      file = ./secrets/client-secret.age;
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };

    alertmanager-telegram-token = {
      file = ./secrets/telegram-token.age;
      mode = "0400";
    };
  };
  # Comin
  services.comin = {
    enable = true;
    hostname = "observability";
    remotes = [{
      name = "origin";
      url = "https://github.com/gianklug/nixos-vms";
      branches.main.operation = "switch";
    }];
  };
  system.stateVersion = "25.10";
}
