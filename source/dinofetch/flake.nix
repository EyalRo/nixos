{
  description = "dinofetch Zig tool dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          starship
          zig
        ];

        shellHook = ''
          export STARSHIP_CONFIG=${./starship/develop.toml}
          export STARSHIP_SHELL=bash
          if command -v starship >/dev/null 2>&1; then
            eval "$(starship init bash)"
          fi
        '';
      };
    };
}
