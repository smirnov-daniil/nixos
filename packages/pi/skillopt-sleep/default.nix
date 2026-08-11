{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.skillopt-sleep = pkgs.python3Packages.buildPythonApplication {
      pname = "skillopt-sleep";
      version = "0.2.0-unstable-2026-08-02";
      src = inputs.skillopt;
      pyproject = true;
      build-system = with pkgs.python3Packages; [
        setuptools
        wheel
      ];
      patches = [./pi-safety.patch];
      postPatch = ''
        ${pkgs.python3}/bin/python - <<'PY'
        import re
        from pathlib import Path

        path = Path("pyproject.toml")
        text = path.read_text()
        text, count = re.subn(r'dependencies = \[\n.*?\n\]', 'dependencies = []', text, count=1, flags=re.S)
        if count != 1:
            raise RuntimeError("project dependencies block changed")

        def replace_once(value, old, new):
            if value.count(old) != 1:
                raise RuntimeError(f"expected one occurrence of {old!r}")
            return value.replace(old, new)

        text = replace_once(text, 'skillopt-train = "scripts.train:main"\n', "")
        text = replace_once(text, 'skillopt-eval = "scripts.eval_only:main"\n', "")
        text = replace_once(text, 'include = ["skillopt", "skillopt.*", "skillopt_sleep", "skillopt_sleep.*", "skillopt_webui", "skillopt_webui.*", "scripts*"]', 'include = ["skillopt_sleep", "skillopt_sleep.*"]')
        path.write_text(text)
        PY
        cp ${./test-pi-safety.py} tests/test_pi_package_safety.py
      '';
      nativeCheckInputs = [pkgs.python3Packages.pytestCheckHook];
      enabledTestPaths = [
        "tests/test_backend_pi.py"
        "tests/test_harvest_pi.py"
        "tests/test_pi_integration.py"
        "tests/test_pi_package_safety.py"
      ];
      pythonImportsCheck = ["skillopt_sleep"];
      meta = {
        description = "Validation-gated offline skill optimization for Pi sessions";
        homepage = "https://github.com/microsoft/SkillOpt";
        license = lib.licenses.mit;
        mainProgram = "skillopt-sleep";
      };
    };
  };
}
