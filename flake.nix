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
        # "c"
        # "rust"
        "haskell"
      ];
      system = "x86_64-linux";

      useC = builtins.elem "c" need_language;
      useRust = builtins.elem "rust" need_language;
      useHaskell = builtins.elem "haskell" need_language;

      overlayRust =
        addByFlag useRust
          [ ]
          [
            inputs.rust-overlay.overlays.default
            self.overlays.rust
          ];

      final-overlays = [ ] ++ overlayRust;

      pkgs = import nixpkgs {
        inherit system;
        overlays = final-overlays;
      };
      pkgs_c = addByFlag useC [ ] (import ./modules/c.nix { inherit pkgs; });
      env_c = addByFlag useC { } {
        # 暂无
      };

      pkgs_rust = addByFlag useRust [ ] (import ./modules/rust.nix { inherit pkgs; });
      env__rust = addByFlag useRust { } {
        # Required by rust-analyzer
        RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
      };

      pkgs_haskell = addByFlag useHaskell [ ] (import ./modules/haskell.nix { inherit pkgs; });
      env_haskell = addByFlag useHaskell { } {
        # 暂无
      };

      # 解析 临时 path 路径
      # 相对路径写法: 相对于 flake.nix 所在目录开始写
      # 绝对路径写法: 直接写
      shell_path = [
        # "coding/scripts"
      ];

    in
    {

      lib = {
        addByFlag =
          flag: default: value:
          if flag then value else default;
      };

      overlays = {
        rust =
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
      };

      devShells."${system}".default = pkgs.mkShell {
        packages = [ ] ++ pkgs_c ++ pkgs_rust ++ pkgs_haskell;

        env = { } // env__rust // env_c // env_haskell;

        # 拼接 path 路径
        shellHook = ''
          ${builtins.concatStringsSep "\n" (builtins.map (p: "export PATH=$PWD/${p}:$PATH") shell_path)}
        '';
      };
    };
}
