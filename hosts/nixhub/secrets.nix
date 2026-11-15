let
  nixhub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGECTQ9kbu3nBUs6IiR9xGh8CoikobspLZ2CID3c0LHs root@nixhub";
  me = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILR+yp3S4CsMFq85XQqgB5lcxcOCQm2AeGHpoarPwSNt giank@nanopad";
  gk-yubikey = "age1yubikey1qfj5nyrl7zrcvc6q8nl5ac2sej5jns066s3v44qk7h3cgd8pwte0ss6s3n6";
in
{
  # fine-grained GitHub token: nixos-config contents RW, nix-flake-burpsuitepro read
  "secrets/github-token.age".publicKeys = [ nixhub me gk-yubikey ];
}
