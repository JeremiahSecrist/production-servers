{lib, config, ...}: {
  age.secrets.mailserver = {
    file = ../../../secrets/mailserver;
    # path = "/var/lib/secrets/nextcloudpass";
    mode = "700";
    owner = "mailserver";
  };
  mailserver = {
    enable = true;
    fqdn = "mail.arouzing.win";
    domains = ["arouzing.win"];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "admin@arouzing.win" = {
        hashedPasswordFile = config.age.secrets.mailserver.path;
        # aliases = ["admin@arouzing.win"];
      };
      # "user2@example.com" = { ... };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = "acme-nginx";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "owner@arouzing.win";
}
