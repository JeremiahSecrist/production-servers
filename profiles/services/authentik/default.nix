{
  config,
  pkgs,
  lib,
  ...
}: {
  services.authentik = {
    enable = true;
    # The environmentFile needs to be on the target host!
    # Best use something like sops-nix or agenix to manage it
    environmentFile = config.age.secrets.authentikenv.path; #TODO: sops config
    nginx = {
      enable = true;
      enableACME = true;
      host = "auth.arouzing.win";
    };
    settings = {
      email = {
        host = "mail.arouzing.win";
        port = 587;
        username = "authentik@arouzing.win";
        use_tls = true;
        use_ssl = false;
        from = "authentik@arouzing.win";
      };
      disable_startup_analytics = true;
      avatars = "initials";
    };
  };
  age.secrets = {
    authentikenv = {
      file = ../../../secrets/authentikenv;
      mode = "770";
      owner = "authentik";
      group = "authentik";
    };
  };
}
