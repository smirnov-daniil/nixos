{inputs, ...}: {
  flake.nixosModules.pi = {
    pkgs,
    config,
    ...
  }: {
    imports = [inputs.pi.nixosModules.default];
    programs.pi.coding-agent = {
      enable = true;

      # custom package
      # package = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;

      # target users
      # users = [ "lukas" ]; # defaults to all normal users

      # appended to the system prompt
      # rules = ''
      #   # AGENTS.md
      #   Be concise.
      # '';

      # extra skills
      # skills = [ ./skills/my-skill ];

      # extra extensions
      # extensions = [ ./extensions/my-extension.ts ];

      # extra themes
      # themes = [ ./themes/catppuccin-mocha.json ];

      # extra prompt templates
      # promptTemplates = [ ./prompts ./prompt-templates/review.md ];

      # ~/.pi/agent/models.json
      # models = ./models.json;

      # extra raw CLI flags
      # extraFlags = [ "--provider" "openai" "--model" "gpt-5" ];

      # environment variables or env file
      # environment = {
      #   OPENAI_API_KEY = config.age.secrets.openai.path;
      # };
      # environment = ./pi.env;
    };
  };
}
