{
  pkgs,
  lib,
  config,
  ...
}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      # for gpg tunnel
      StreamLocalBindUnlink yes
    '';
    startWhenNeeded = true;
    # kexAlgorithms = [ "curve25519-sha256@libssh.org" ];
  };
  nix.settings.trusted-users = ["@wheel"];
  security = {
    sudo.execWheelOnly = true;
    pam = {
      enableSSHAgentAuth = true;
      services.sudo.sshAgentAuth = true;
    };
  };
}
