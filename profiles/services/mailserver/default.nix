{
  lib,
  config,
  ...
}: let
  domain = "arouzing.win";
in {
  services.roundcube = {
    enable = true;
    hostName = domain;
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };
  services.nginx = {
    enable = true;
    virtualHosts.${domain} = {
      serverName = domain;
      forceSSL = true;
      enableACME = true;
      acmeRoot = "/var/lib/acme/acme-challenge";
    };
  };
  mailserver = {
    enable = true;
    fqdn = "mail.${domain}";
    domains = [domain];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "admin@arouzing.win".hashedPasswordFile = config.age.secrets.admin.path;
      "authentik@arouzing.win".hashedPasswordFile = config.age.secrets.authentik.path;
      "hodbogi@arouzing.win".hashedPasswordFile = config.age.secrets.zoid.path;
    };
    certificateScheme = "acme-nginx";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "owner@arouzing.xyz";
  };
  age.secrets = {
    admin = {
      file = ../../../secrets/mailserverusers/admin;
      mode = "770";
      owner = "dovecot2";
      group = "dovecot2";
    };
    authentik = {
      file = ../../../secrets/mailserverusers/authentik;
      mode = "770";
      owner = "dovecot2";
      group = "dovecot2";
    };
    zoid = {
      file = ../../../secrets/mailserverusers/zoid;
      mode = "770";
      owner = "dovecot2";
      group = "dovecot2";
    };
  };
}
