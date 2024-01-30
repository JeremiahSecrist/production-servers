{
  lib,
  pkgs,
  config,
  ...
}: {
  users.users = {
    sky = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAGm66rJsr8vjRCYDkH4lEPncPq27o6BHzpmRmkzOiM"
      ];
      extraGroups = ["wheel" "docker"];
    };
  };
}
