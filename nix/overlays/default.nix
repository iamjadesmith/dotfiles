{ inputs, ... }:
{
  additions = final: _prev: import ../pkgs final.pkgs;

  modifications = final: prev: {
    tree-sitter-cli = prev.rustPlatform.buildRustPackage {
      pname = "tree-sitter-cli";
      version = "0.26.1";
      src = inputs.tree-sitter-src;
      buildAndTestSubdir = "crates/cli";
      cargoBuildFlags = [
        "-p"
        "tree-sitter-cli"
      ];
      cargoLock.lockFile = "${inputs.tree-sitter-src}/Cargo.lock";
      nativeBuildInputs = [
        prev.llvmPackages.libclang
      ];
      LIBCLANG_PATH = "${prev.llvmPackages.libclang.lib}/lib";
      BINDGEN_EXTRA_CLANG_ARGS = prev.lib.optionalString prev.stdenv.hostPlatform.isLinux "-isystem ${prev.stdenv.cc.libc.dev}/include";
      doCheck = false;

      meta = prev.tree-sitter.meta // {
        mainProgram = "tree-sitter";
      };
    };
  };

  unstable = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
