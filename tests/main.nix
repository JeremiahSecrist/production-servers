{ self
, inputs
, pkgs
, ...
}: {
  name = "nextcloud";
  hostPkgs = pkgs;
  imports = [
    {
      nodes.machine =
        { lib
        , pkgs
        , config
        , ...
        }: {
          imports = [
            inputs.agenix.nixosModules.default
            # self.nixosModules.authentik
            # inputs.nixos-generators.nixosModules.linode
            # {
            #   services.tailscale.enable = lib.mkForce false;
            #   services.nextcloud.config = {
            #     adminpassFile = lib.mkForce "${pkgs.writeText "aaa" "aaa"}";
            #   };
            # }
          ];
        };
    }
  ];
  testScript = { nodes, ... }: ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    # machine.succeed("nextcloud-occ status")
  '';
}
