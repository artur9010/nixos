{
  pkgs,
  lib,
  ...
}:

let
  duckduckgo-mcp-server = pkgs.python3Packages.buildPythonApplication rec {
    pname = "duckduckgo-mcp-server";
    version = "0.1.1";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "nickclyde";
      repo = "duckduckgo-mcp-server";
      rev = "d198a2f0e8bd7c862d87d8517e1518aa295f8348";
      hash = "sha256-aoWU5AVErAt73V+BgveEmVnjNh/cteS+A9AIFLylOsw=";
    };

    build-system = [ pkgs.python3Packages.hatchling ];

    dependencies = [
      pkgs.python3Packages.beautifulsoup4
      pkgs.python3Packages.httpx
      pkgs.python3Packages.mcp
    ];

    pythonImportsCheck = [ "duckduckgo_mcp_server" ];

    meta = {
      description = "MCP Server for searching via DuckDuckGo";
      homepage = "https://github.com/nickclyde/duckduckgo-mcp-server";
      license = lib.licenses.mit;
      mainProgram = "duckduckgo-mcp-server";
    };
  };
in
{
  environment.systemPackages = [ duckduckgo-mcp-server ];
}
