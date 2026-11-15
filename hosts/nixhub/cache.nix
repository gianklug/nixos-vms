# Binary cache: harmonia serves this host's /nix/store on :5000, signed with a key
# that is generated once on first boot (the CT rootfs is persistent).
# Public key for the laptops' trusted-public-keys:  cat /var/lib/harmonia/cache-pub-key
{ pkgs, ... }:
let
  keyName = "nixhub.int.gk.wtf-1";
  keyDir = "/var/lib/harmonia";
in
{
  systemd.services.harmonia-keygen = {
    description = "Generate the harmonia binary cache signing key";
    wantedBy = [ "multi-user.target" ];
    before = [ "harmonia.service" ];
    requiredBy = [ "harmonia.service" ];
    unitConfig.ConditionPathExists = "!${keyDir}/cache-priv-key";
    serviceConfig.Type = "oneshot";
    script = ''
      install -d -m 0700 ${keyDir}
      ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${keyName} \
        ${keyDir}/cache-priv-key ${keyDir}/cache-pub-key
      chmod 0400 ${keyDir}/cache-priv-key
      chmod 0444 ${keyDir}/cache-pub-key
    '';
  };

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ "${keyDir}/cache-priv-key" ];
    settings = {
      bind = "[::]:5000";
      # cache.nixos.org has priority 40; prefer it for everything it has.
      priority = 50;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
