# nixhub: Nix builder + binary cache for the laptops (github:gianklug/nixos-config).
# Proxmox CT 131 on nuc (NetBox: nixhub). rootfs on wd-black (SSD, also the build
# dir), /nix on TrueNAS iSCSI (150G).
{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./cache.nix
    ./update.nix
  ];

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };
  services.fstrim.enable = false; # Let Proxmox host handle fstrim

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # The sandbox works in this unprivileged CT (nesting=1).
      sandbox = true;
      # Stay within the 6 GB memory cap of the CT.
      max-jobs = 2;
      cores = 3;
      # Same extra cache the laptops use (nixConfig in nixos-config), so Hyprland
      # is downloaded instead of compiled.
      extra-substituters = [ "https://hyprland.cachix.org" ];
      extra-trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      min-free = 10 * 1024 * 1024 * 1024; # start GC below 10 GiB free
      max-free = 30 * 1024 * 1024 * 1024;
    };
    # Built systems are kept alive by the gcroots of the update job.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILR+yp3S4CsMFq85XQqgB5lcxcOCQm2AeGHpoarPwSNt giank@nanopad"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOQ9lnwVsJAhd98vdE4mXuOWRtvuWFqyJRke3g76qaxHAAAABHNzaDo= gk@gk.wtf"
  ];

  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [
      "systemd"
      "textfile"
    ];
    extraFlags = [ "--collector.textfile.directory=/var/lib/node-exporter-textfile" ];
  };
  systemd.tmpfiles.rules = [ "d /var/lib/node-exporter-textfile 0755 root root -" ];

  # Cache DNS lookups to improve performance
  services.resolved.settings = {
    Resolve = {
      Cache = true;
      CacheFromLocalhost = true;
      Domains = [ "~." ];
      FallbackDNS = [ "192.168.1.1" ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim-full
    htop
    git
    jq
  ];

  services.comin = {
    enable = true;
    hostname = "nixhub";
    remotes = [
      {
        name = "origin";
        url = "https://github.com/gianklug/nixos-vms";
        branches.main.operation = "switch";
      }
    ];
  };

  system.stateVersion = "25.11";
}
