{ pkgs ? import <nixpkgs> {} }:

pkgs.llama-cpp.override {
  cudaSupport = true;
}