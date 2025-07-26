{
  description = "A big flake for all the coding language";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let

      # help function
      # get 3 parameters boolean-flag default-value true-value
      addByFlag = self.outputs.lib.addByFlag;


      # 仅仅需要修改语言配置, 如果需要更多 pkgs . 修改对应modules下的nix文件
      need_language = [
        "c"
        "rust"
      ];
      system = "x86_64-linux";

      useC = builtins.elem "c" need_language;
      useRust = builtins.elem "rust" need_language;

      final-overlays =
        [ ]
        ++ (addByFlag useRust
          [ ]
          [
            inputs.rust-overlay.overlays.default
            self.overlays.default
          ]
        )

      ;

      pkgs = import nixpkgs {
        inherit system;
        overlays = final-overlays;
      };
      c = addByFlag useC [ ] (import ./modules/c.nix { inherit pkgs; });
      rust = addByFlag useRust [ ] (import ./modules/rust.nix { inherit pkgs; });

    in
    {

      lib = {
        addByFlag =
          flag: default: value:
          if flag then value else default;
      };

      overlays.default =
        final: prev:

        self.outputs.lib.addByFlag useRust { } {

          rustToolchain =
            let
              rust = prev.rust-bin;
            in
            if builtins.pathExists ./rust-toolchain.toml then
              rust.fromRustupToolchainFile ./rust-toolchain.toml
            else if builtins.pathExists ./rust-toolchain then
              rust.fromRustupToolchainFile ./rust-toolchain
            else
              rust.stable.latest.default.override {
                extensions = [
                  "rust-src"
                  "rustfmt"
                ];
              };
        };

      devShells."${system}".default = pkgs.mkShell {
        packages =
          [ ] ++ c ++ rust
        ;
      };
    };
}
