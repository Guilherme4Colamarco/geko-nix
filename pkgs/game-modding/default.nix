# Versões fixadas das ferramentas de mods e engenharia reversa do AI Search.
{ pkgs, lib, ... }:
let
  py = pkgs.python313.pkgs;
  sources = {
    universal-modder = pkgs.fetchFromGitHub {
      owner = "rehan-remade";
      repo = "universal-modder";
      rev = "76b9c7e77ead5fd2d5f1b7613c6a7ed591b01c70";
      hash = "sha256-TpfHx3/RbrPnRVj1W9KhX2p7KG5o2ZGR96oZLPBlI9A=";
    };
    ghidra-mcp = pkgs.fetchFromGitHub {
      owner = "bethington";
      repo = "ghidra-mcp";
      rev = "4c5e9429eddc7100be6b4d6bad561d69ab86938f";
      hash = "sha256-44EJdgaWqlaeImPwkXZOmEhk5/2OV576HuxKMrGypIA=";
    };
    ida-mcp = pkgs.fetchFromGitHub {
      owner = "HexRaysSA";
      repo = "ida-mcp";
      rev = "930d5216a55ffee9843d4ded76593e44e38d895f";
      hash = "sha256-HKQXeSDNx3HngwrAW0Lmk4uMhhMPc43YJ/TbWhgFOsY=";
    };
  };
  # O MCP exige ida-domain 0.5.1; o nixpkgs fixado ainda traz 0.5.0.
  ida-domain = py.ida-domain.overridePythonAttrs (old: {
    version = "0.5.1";
    src = pkgs.fetchPypi {
      pname = "ida_domain";
      version = "0.5.1";
      hash = "sha256-xJ8sQXBH2ILpVPZRtQpwmj8nkDszulM7eUqlTWU20W8=";
    };
    build-system = [ py.hatchling ];
    meta = old.meta // {
      changelog = "https://github.com/HexRaysSA/ida-domain/releases/tag/v0.5.1";
    };
  });
  ida-nexus = py.buildPythonPackage {
    pname = "ida-nexus";
    version = "0.13.3";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "ida_nexus";
      version = "0.13.3";
      hash = "sha256-13pw8oYzn6F+tpLSgqVSILg81W7s6m465k0iCRxhcjI=";
    };
    build-system = [ py.hatchling ];
    dependencies = [ ida-domain ];
    # Testes de análise exigem uma instalação de IDA/idalib.
    doCheck = false;
    pythonImportsCheck = [ "ida_nexus" ];
    meta.license = lib.licenses.mit;
  };
  zeromcp = py.buildPythonPackage {
    pname = "zeromcp";
    version = "1.10.3";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "zeromcp";
      version = "1.10.3";
      hash = "sha256-cSMdstEy4+AuOxCuHLSISa/271q73gf/0j0QcaysuuY=";
    };
    build-system = [ py.hatchling ];
    doCheck = false;
    pythonImportsCheck = [ "zeromcp" ];
    meta.license = lib.licenses.mit;
  };
in
{
  inherit sources;
  universal-modder = py.buildPythonApplication {
    pname = "universal-modder";
    version = "0.2.0";
    src = sources.universal-modder;
    pyproject = true;
    build-system = [ py.hatchling ];
    dependencies = [ py.pillow py.numpy py.pyyaml ];
    doCheck = false;
    pythonImportsCheck = [ "um.cli" ];
    makeWrapperArgs = [ "--set" "UM_KB" "${sources.universal-modder}/knowledge" ];
    meta = {
      description = "Ferramentas e base de conhecimento para mods com agentes de IA";
      homepage = "https://github.com/rehan-remade/universal-modder";
      license = lib.licenses.mit;
      mainProgram = "um";
    };
  };
  ghidra-mcp = py.buildPythonApplication {
    pname = "ghidra-mcp-bridge";
    version = "7.0.0";
    src = sources.ghidra-mcp;
    pyproject = true;
    build-system = [ py.hatchling ];
    dependencies = [ py.mcp py.pydantic ];
    doCheck = false;
    pythonImportsCheck = [ "bridge_mcp_ghidra.cli" ];
    meta = {
      description = "Ponte MCP para uma instância de Ghidra";
      homepage = "https://github.com/bethington/ghidra-mcp";
      license = lib.licenses.asl20;
      mainProgram = "bridge-mcp-ghidra";
    };
  };
  ida-mcp = py.buildPythonApplication {
    pname = "ida-mcp";
    version = "20261003.0.1";
    src = sources.ida-mcp;
    pyproject = true;
    build-system = [ py.hatchling ];
    dependencies = [ py.packaging ida-nexus zeromcp ];
    doCheck = false;
    pythonImportsCheck = [ "ida_mcp.cli" ];
    meta = {
      description = "Servidor MCP oficial Hex-Rays para IDA";
      homepage = "https://github.com/HexRaysSA/ida-mcp";
      license = lib.licenses.mit;
      mainProgram = "ida-mcp";
    };
  };
  rea = pkgs.callPackage ./rea.nix { };
}
