{ ... }:

{
  # unsloth-studio downloads prebuilt runtimes at first run (uv, uv-managed
  # CPython, torch wheels, llama.cpp/whisper.cpp builds). Those binaries have
  # /lib64/ld-linux-x86-64.so.2 hardcoded as their interpreter, which does
  # not exist on NixOS unless nix-ld provides it. The app itself sets
  # NIX_LD/NIX_LD_LIBRARY_PATH for its own process tree; this only installs
  # the /lib64 shim.
  programs.nix-ld.enable = true;
}
