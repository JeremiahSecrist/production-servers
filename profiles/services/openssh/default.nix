{ pkgs
, lib
, config
, ...
}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    startWhenNeeded = true;
    # kexAlgorithms = [ "curve25519-sha256@libssh.org" ];
  };
  security = {
    sudo.execWheelOnly = true;
    pam = {
      sshAgentAuth.enable = true;
      services.sudo.sshAgentAuth = true;
    };
  };
}
