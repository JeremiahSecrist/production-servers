{ config, lib, ... }:
let
  cfg = config.local.remoteBuild;
in
{
  options.local.remoteBuild = {
    enable = lib.mkEnableOption "";
    isBuilder = lib.mkEnableOption "";
    hostName = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
    privKey = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
    userKeys = lib.mkOption {
      type = with lib.types; listOf str;
      default = null;
    };
  };
  config = lib.mkIf cfg.enable {
        users = {
          groups.builder = { };
          users.builder = {
            createHome = false;
            isSystemUser = true;
            openssh.authorizedKeys = {
              keys = cfg.userKeys;
            };
            useDefaultShell = true;
            group = "builder";
          };
        };

        nix = {
          settings = {
            builders-use-substitutes = true;
            trusted-users = [
              "builder"
              "nix-ssh"
            ];
            keep-outputs = true;
            keep-derivations = true;
            secret-key-files = cfg.privKey;
          };
          sshServe = {
            enable = true;
            write = true;
            protocol = "ssh-ng";
            keys = cfg.userKeys;
          };
        };
    };
}