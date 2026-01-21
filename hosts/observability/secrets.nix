let
  observability = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWBHY0tU1y4EjJZXUylLAq36lieBtRSzqPcWzFoXhm7 root@observability";
  me   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILR+yp3S4CsMFq85XQqgB5lcxcOCQm2AeGHpoarPwSNt giank@nanopad";
in
{
  "secrets/client-secret.age".publicKeys = [ observability me ];
  "secrets/telegram-token.age".publicKeys = [ observability me ];
}

