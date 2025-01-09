{
  programs.nixvim.plugins.lsp = {
    enable = true;

    servers = {
      nixd = {
        enable = true;
#        nixpkgs = {
#          expr = "import <nixpkgs> {}";
#        };
#        formatting = {
#          command = [ "alejandra" ];
#        };
      };
    };
  };
}
