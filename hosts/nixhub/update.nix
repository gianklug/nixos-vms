# Nightly: update nixos-config's flake.lock, build every listed host, and push the
# new lock to main only if all of them build. Afterwards build the pushed revision
# exactly the way the laptops' autoUpgrade does (github:…/<rev>), so the paths
# they ask for are in this host's store and served by harmonia.
# Logs: journalctl -u nixos-config-update   Run now: systemctl start nixos-config-update
{
  config,
  lib,
  pkgs,
  ...
}:
let
  repo = "gianklug/nixos-config";
  # Hosts of nixos-config to keep built. "nixos" is left out: it needs the gated
  # Binary Ninja download in its store, which this builder doesn't have.
  hosts = [
    "nixowos"
    "travel"
  ];
  stateDir = "/var/lib/nixos-config-update";
in
{
  age.secrets.github-token = {
    # fine-grained token: nixos-config contents read/write, nix-flake-burpsuitepro read
    file = ./secrets/github-token.age;
    mode = "0400";
  };

  systemd.services.nixos-config-update = {
    description = "Update nixos-config flake.lock, build all hosts, push if green";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      config.nix.package
      git
      jq
      coreutils
      openssh
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "nixos-config-update";
      WorkingDirectory = stateDir;
      Nice = 10;
      IOSchedulingClass = "idle";
      TimeoutStartSec = "6h";
    };
    script = ''
      set -euo pipefail
      token=$(cat ${config.age.secrets.github-token.path})
      export NIX_CONFIG="access-tokens = github.com=$token"
      auth="Authorization: Basic $(printf 'x-access-token:%s' "$token" | base64 -w0)"
      gitauth() { git -c http.extraHeader="$auth" "$@"; }

      if [ ! -d checkout/.git ]; then
        gitauth clone https://github.com/${repo} checkout
      fi
      cd checkout
      gitauth fetch origin main
      git checkout -B main origin/main
      git reset --hard origin/main
      git clean -fdx

      nix flake update

      mkdir -p ../gcroots
      for h in ${lib.escapeShellArgs hosts}; do
        echo ">>> building candidate $h"
        nix build --print-build-logs \
          ".#nixosConfigurations.$h.config.system.build.toplevel" \
          --out-link "../gcroots/candidate-$h"
      done

      if git diff --quiet flake.lock; then
        echo "flake.lock unchanged"
      else
        git add flake.lock
        git -c user.name=nixhub -c user.email=nixhub@gk.wtf \
          commit -m "chore: update flake.lock (all hosts build on nixhub)"
        gitauth push origin main
      fi

      rev=$(git rev-parse HEAD)
      for h in ${lib.escapeShellArgs hosts}; do
        echo ">>> building $h at $rev (as the laptops will)"
        nix build "github:${repo}/$rev#nixosConfigurations.$h.config.system.build.toplevel" \
          --out-link "../gcroots/$h"
      done
    '';
  };

  systemd.timers.nixos-config-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}
