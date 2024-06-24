{ lib
, pkgs
, config
, ...
}: {
  nix.settings.trusted-users = [ "sky" ];
  users.users = {
    sky = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAGm66rJsr8vjRCYDkH4lEPncPq27o6BHzpmRmkzOiM"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBA9i9HoP7X8Ufzz8rAaP7Nl3UOMZxQHMrsnA5aEQfpTyIQ1qW68jJ4jGK5V6Wv27MMc3czDU1qfFWIbGEWurUHQ="
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZKIVAuSFA4ZZVfmTsymM+6A+XuJlVnj1YO+Mh5T4BR root@lappy"
      ];
      extraGroups = [ "wheel" "docker" ];
    };
  };
}
