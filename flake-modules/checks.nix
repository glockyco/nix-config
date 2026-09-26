{
  hosts,
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      fleetBindings,
      ...
    }:
    let
      inherit (fleetBindings)
        host
        onDarwinHost
        onNixosHost
        hostConfiguration
        openspec
        configuredHost
        binaryCaches
        tailnetPeers
        managedHosts
        tailnetPolicyRenderer
        tailnetPolicy
        tailnetPolicyCheck
        tailnetPolicyRejectsCheck
        tailscaleSetAfterLoginTest
        markdownOxide
        roslynLanguageServer
        personalOmp
        moduleImportsCheck
        moduleImportsCommandTest
        hostDeclarationCheck
        airBatchCheck
        airBatchCommandTest
        airBatchConfigCheck
        containerRuntimeCheck
        containerRuntimeCommandTest
        containerRuntimeConfigCheck
        wslOpen
        wslOpenCommandTest
        windowsConfiguration
        windowsConfigurationCheck
        korolevConfig
        korolevBuildMachines
        korolevBuildMachine
        korolevUser
        korolevHome
        korolevShell
        ompBrowserRuntimeCheck
        ;
    in
    {
      checks = {
        markdownOxideVersion =
          pkgs.runCommand "check-markdown-oxide-version" { nativeBuildInputs = [ markdownOxide ]; }
            ''
              test "$(markdown-oxide --version)" = "markdown-oxide ${markdownOxide.version}"
              touch $out
            '';

        roslynInitialization =
          pkgs.runCommand "check-roslyn-language-server-initialization"
            {
              nativeBuildInputs = [
                pkgs.python3
                roslynLanguageServer
              ];
              meta.timeout = 60;
            }
            ''
              export HOME=$TMPDIR/home
              mkdir -p "$HOME"
              python3 - Microsoft.CodeAnalysis.LanguageServer <<'PY'
              import json
              import pathlib
              import subprocess
              import sys
              import tempfile
              import threading

              with tempfile.TemporaryDirectory() as directory:
                  root = pathlib.Path(directory)
                  document = root / "Example.cs"
                  document.write_text("class Before {}\n", encoding="utf-8")
                  server = subprocess.Popen(
                      [sys.argv[1], "--stdio", "--logLevel", "Error"],
                      stdin=subprocess.PIPE,
                      stdout=subprocess.PIPE,
                      cwd=root,
                  )
                  deadline = threading.Timer(30, server.kill)
                  deadline.start()

                  def send(message):
                      body = json.dumps({"jsonrpc": "2.0", **message}).encode()
                      server.stdin.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
                      server.stdin.flush()

                  def receive(request_id):
                      while True:
                          headers = {}
                          while True:
                              line = server.stdout.readline()
                              if not line:
                                  raise AssertionError("Roslyn closed its output before replying")
                              if line == b"\r\n":
                                  break
                              key, value = line.decode().split(":", 1)
                              headers[key.lower()] = value.strip()
                          message = json.loads(server.stdout.read(int(headers["content-length"])))
                          if "id" not in message:
                              continue
                          if "method" in message:
                              assert message["method"] in ("workspace/configuration", "client/registerCapability"), message
                              result = [None for _ in message["params"]["items"]] if message["method"] == "workspace/configuration" else None
                              send({"id": message["id"], "result": result})
                              continue
                          assert message["id"] == request_id, message
                          assert "error" not in message, message
                          return message.get("result")

                  try:
                      send({"id": 1, "method": "initialize", "params": {
                          "processId": None,
                          "rootUri": root.as_uri(),
                          "capabilities": {"textDocument": {"documentSymbol": {
                              "hierarchicalDocumentSymbolSupport": True
                          }}},
                      }})
                      receive(1)
                      send({"method": "initialized", "params": {}})
                      send({"method": "textDocument/didOpen", "params": {"textDocument": {
                          "uri": document.as_uri(), "languageId": "csharp", "version": 1,
                          "text": "class Before {}\n",
                      }}})
                      send({"id": 2, "method": "textDocument/documentSymbol", "params": {
                          "textDocument": {"uri": document.as_uri()},
                      }})
                      assert [symbol["name"] for symbol in receive(2)] == ["Before"]
                      send({"method": "textDocument/didChange", "params": {
                          "textDocument": {"uri": document.as_uri(), "version": 2},
                          "contentChanges": [{"text": "class After {}\n"}],
                      }})
                      send({"id": 3, "method": "textDocument/documentSymbol", "params": {
                          "textDocument": {"uri": document.as_uri()},
                      }})
                      assert [symbol["name"] for symbol in receive(3)] == ["After"]
                      send({"id": 4, "method": "shutdown"})
                      receive(4)
                      send({"method": "exit"})
                      server.stdin.close()
                      assert server.wait(timeout=5) == 0
                      print("Roslyn initializes and applies whole-document updates without a restart.")
                  finally:
                      deadline.cancel()
                      if server.poll() is None:
                          server.kill()
                      server.wait()
              PY
              touch $out
            '';

        # An unimported module is absent rather than an error.
        # Assert every module is reachable from its sibling `default.nix`.
        moduleImports = pkgs.runCommand "check-module-imports" { } ''
          ${lib.getExe moduleImportsCheck} ${../modules}
          touch $out
        '';

        # Prove that the check above can reject, so an empty result means
        # something.
        moduleImportsCommand = moduleImportsCommandTest;

        # Force representative declarations so option errors cannot stay
        # hidden behind Nix laziness.
        hostDeclaration = hostDeclarationCheck;

        tailnetPolicy = tailnetPolicyCheck;
        tailnetPolicyRejects = tailnetPolicyRejectsCheck;
        tailscaleSetAfterLogin = tailscaleSetAfterLoginTest;

        hostNixSettings =
          let
            settings =
              if host.kind == "darwin" then
                hostConfiguration.config.determinateNix.customSettings
              else
                hostConfiguration.config.nix.settings;
          in
          pkgs.callPackage ../packages/host-nix-settings-check.nix {
            inherit binaryCaches;
            hostName = host.name;
            settings = {
              substituters = settings.extra-substituters;
              trustedPublicKeys = settings.extra-trusted-public-keys;
            };
          };

        # Structure already prevents an asymmetric surface: the shell and
        # the repository checks carry no platform condition, and `systems`
        # derives from the host table. This asserts what structure cannot,
        # so a later edit that reintroduces a condition, or a host added
        # without a table entry, fails in review. It reads other output
        # attributes only, never `checks` itself.
        fleetSurface =
          let
            declared = lib.naturalSort (
              builtins.attrNames self.darwinConfigurations ++ builtins.attrNames self.nixosConfigurations
            );
            bound = lib.naturalSort (map (entry: entry.name) (builtins.attrValues hosts));
          in
          assert self.devShells.${system} ? default;
          assert declared == bound;
          assert hostConfiguration.pkgs.stdenv.hostPlatform.system == system;
          pkgs.runCommand "check-fleet-surface" { } "touch $out";

        personalOmpUpdate = personalOmp.devUpdate.tests;

        personalOmpShape =
          let
            homeConfiguration = hostConfiguration.config.home-manager.users.${configuredHost.username};
            installed = map toString homeConfiguration.home.packages;
            zshInit = homeConfiguration.programs.zsh.initContent;
          in
          assert builtins.elem (toString personalOmp) installed;
          assert builtins.elem (toString personalOmp.devUpdate) installed;
          assert builtins.elem (toString personalOmp.verifyPersonalOmp) installed;
          assert lib.hasInfix "path=(\"/etc/profiles/per-user/${configuredHost.username}/bin\"" zshInit;
          pkgs.runCommand "check-personal-omp-shape"
            {
              nativeBuildInputs = [ pkgs.jq ] ++ personalOmp.languageServers;
            }
            ''
              test -x ${personalOmp}/bin/omp
              test -x ${personalOmp.devUpdate}/bin/omp-dev-update
              test -x ${personalOmp.verifyPersonalOmp}/bin/verify-personal-omp

              jq -e '.omp.extensions | index("./extensions/personal-commit.ts") != null' ${personalOmp.plugin}/package.json
              test "$(jq -r '.servers | keys | sort | join(",")' ${personalOmp.plugin}/lsp/lsp.json)" = markdown-oxide,marksman,roslyn-language-server,svelte
              test "$(jq -r '.servers.marksman.disabled' ${personalOmp.plugin}/lsp/lsp.json)" = true

              # The workflow commands ship in the payload, and the LSP root
              # must stay free of them so they register exactly once.
              test -f ${personalOmp.plugin}/commands/opsx-propose.md
              test ! -e ${personalOmp.plugin}/lsp/commands

              command -v Microsoft.CodeAnalysis.LanguageServer
              command -v markdown-oxide
              command -v pyright-langserver
              command -v typescript-language-server
              command -v svelteserver
              command -v nixd
              ! command -v marksman
              command -v texlab
              test "$(${lib.getExe openspec} --version)" = "${openspec.version}"
              touch $out
            '';

        personalOmpGeneration =
          let
            probe = pkgs.writeScript "omp-generation-probe" ''
              #!${pkgs.python3}/bin/python3
              import json, os, shutil, sys
              print(json.dumps({"args": sys.argv[1:], "cwd": os.getcwd(), "omp": shutil.which("omp"), "launcher": sys.argv[0], "nixd": shutil.which("nixd"), "plannotator": shutil.which("plannotator")}))
              sys.exit(int(os.environ.get("PROBE_STATUS", "0")))
            '';
          in
          pkgs.runCommand "check-personal-omp-generation" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            export HOME="$TMPDIR/home with spaces"
            mkdir -p "$HOME"
            python3 - <<'PY'
            import json, os, pathlib, subprocess

            wrapper = "${personalOmp}/bin/omp"
            home = pathlib.Path.home()
            state = home / ".local/share/omp-dev"
            generation = state / "generations/selected generation"
            generation.mkdir(parents=True)
            launcher = generation / "omp"
            launcher.write_bytes(pathlib.Path("${probe}").read_bytes())
            launcher.chmod(0o755)
            current = state / "current"
            current.symlink_to(generation.relative_to(state))
            retained = state / "generations/retained"
            retained.mkdir()
            (retained / "omp").write_text("retained source launcher\n")
            (state / "previous").symlink_to(retained.relative_to(state))
            agent = home / ".omp/agent"
            agent.mkdir(parents=True)
            (agent / "settings.json").write_text('{"defaultModel": "preserve-me"}\n')
            official = home / ".local/lib/oh-my-pi/omp"
            official.parent.mkdir(parents=True)
            official.write_bytes(launcher.read_bytes())
            official.chmod(0o755)
            work = home / "project with spaces"
            work.mkdir()
            plugin_args = ["--extension", "${personalOmp.plugin}", "--plugin-dir", "${personalOmp.plugin}/lsp"]
            conflicting = home / "caller bin"
            conflicting.mkdir()
            (conflicting / "plannotator").write_text("#!/bin/sh\nexit 99\n")
            (conflicting / "plannotator").chmod(0o755)
            caller_path = str(conflicting) + ":" + str(pathlib.Path(wrapper).parent) + ":" + os.environ["PATH"]
            env = dict(os.environ, PATH=caller_path)

            def snapshot():
                return {
                    str(path.relative_to(home)): (
                        path.lstat().st_mode,
                        os.readlink(path) if path.is_symlink() else path.read_bytes() if path.is_file() else None,
                    )
                    for path in home.rglob("*")
                }

            def run(args, status=0):
                before = snapshot()
                result = subprocess.run([wrapper, *args], cwd=work, env=dict(env, PROBE_STATUS=str(status)), text=True, capture_output=True, timeout=15)
                assert snapshot() == before, "wrapper changed source or application state"
                return result

            for args, status in (([], 0), (["--print", "update", "argument with spaces", ""], 23), (["acp"], 0)):
                result = run(args, status)
                assert result.returncode == status, result
                assert json.loads(result.stdout) == {
                    "args": plugin_args + args,
                    "cwd": str(work.resolve()),
                    "omp": wrapper,
                    "launcher": str(launcher.resolve()),
                    "nixd": "${pkgs.nixd}/bin/nixd",
                    "plannotator": "${lib.getExe personalOmp.plannotator}",
                }, result

            result = run(["update", "--check", "argument with spaces"])
            assert result.returncode == 1 and not result.stdout, result
            assert "omp-dev-update" in result.stderr, result

            launcher.chmod(0o644)
            result = run([])
            assert result.returncode == 1 and not result.stdout, result
            assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, result
            launcher.chmod(0o755)
            current.unlink()
            for dangling in (False, True):
                if dangling:
                    current.symlink_to("generations/absent")
                result = run([])
                assert result.returncode == 1 and not result.stdout, result
                assert str(current) in result.stderr and "omp-dev-update" in result.stderr, result
                result = run(["update"])
                assert result.returncode == 1 and not result.stdout, result
                assert "omp-dev-update" in result.stderr and str(current) not in result.stderr, result
            PY
            touch "$out"
          '';

        personalOmpVerification =
          let
            versionProbe = pkgs.writeScript "omp-version-probe" ''
              #!${pkgs.python3}/bin/python3
              import os, sys
              if sys.argv[1:] != ["--extension", "${personalOmp.plugin}", "--plugin-dir", "${personalOmp.plugin}/lsp", "--version"]:
                  sys.exit(2)
              print(os.environ.get("PROBE_VERSION", "18.1.12-patched"))
              sys.exit(int(os.environ.get("PROBE_STATUS", "0")))
            '';
            herdrProbe = pkgs.writeScript "herdr-verification-probe" ''
              #!${pkgs.python3}/bin/python3
              import os, sys
              if sys.argv[1:] != ["integration", "status"]:
                  sys.exit(2)
              print(os.environ.get("STATUS", "omp: current (v8)"))
            '';
          in
          pkgs.runCommand "check-personal-omp-verification" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            export HOME="$TMPDIR/home with spaces"
            mkdir -p "$HOME"
            python3 - <<'PY'
            import json, os, pathlib, subprocess

            state = pathlib.Path.home() / ".local/share/omp-dev"
            generation = state / "generations/verified-generation"
            checkout = generation / "checkout"
            checkout.mkdir(parents=True)
            (generation / "dev-profile").symlink_to("${pkgs.bash}")
            launcher = generation / "omp"
            launcher.write_bytes(pathlib.Path("${versionProbe}").read_bytes())
            launcher.chmod(0o755)
            metadata = {
                "release": "v18.1.12",
                "upstream": "1" * 40,
                "patchBase": "a1b254047d12e143b7c6011536e918c6c35c5906",
                "patchTip": "62aa62869813e2834dc5887453f0f6c984953442",
                "commit": "2" * 40,
                "system": "${system}",
            }
            manifest = generation / "generation.json"
            manifest.write_text(json.dumps(metadata))
            current = state / "current"
            current.symlink_to(generation.relative_to(state))
            env = dict(os.environ, HERDR_BIN="${herdrProbe}")

            def run(**overrides):
                return subprocess.run(["${lib.getExe personalOmp.verifyPersonalOmp}"], env=dict(env, **overrides), text=True, capture_output=True)

            result = run()
            assert result.returncode == 0, result
            for value in (*metadata.values(), "18.1.12-patched", "${personalOmp.plugin}", "plannotator ${personalOmp.plannotator.version}", "${lib.getExe personalOmp.plannotator}", "omp: current (v8)"):
                assert value in result.stdout, (value, result)
            for overrides in ({"STATUS": "omp: outdated (v7)"}, {"PROBE_VERSION": ""}, {"PROBE_STATUS": "23"}):
                result = run(**overrides)
                assert result.returncode != 0 and not result.stdout, result

            manifest.write_text("invalid json")
            result = run()
            assert result.returncode != 0 and not result.stdout, result
            manifest.write_text(json.dumps(metadata))
            launcher.unlink()
            result = run()
            assert result.returncode == 1 and not result.stdout, result
            assert str(launcher.resolve()) in result.stderr and "omp-dev-update" in result.stderr, result
            current.unlink()
            result = run()
            assert result.returncode == 1 and not result.stdout, result
            assert str(current) in result.stderr and "omp-dev-update" in result.stderr, result
            PY
            touch "$out"
          '';

        herdrOmpReconciliation = pkgs.runCommand "check-herdr-omp-reconciliation" { } ''
          stub=$TMPDIR/herdr-stub
          cat > "$stub" <<'EOF'
          #!${pkgs.runtimeShell}
          test -d "$OMP_AGENT_DIR"
          printf '%s\n' "$*" >> "$CALLS"
          if [ "$1 $2" = "integration status" ]; then
            printf '%s\n' "''${STATUS:-}"
          elif [ "$1 $2 $3" = "integration install omp" ]; then
            if [ ! -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts" ]; then
              test ! -e "$OMP_AGENT_DIR/extensions"
            fi
            mkdir -p "$OMP_AGENT_DIR/extensions"
            touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
          fi
          EOF
          chmod +x "$stub"
          export HERDR_BIN="$stub"

          export OMP_AGENT_DIR=$TMPDIR/missing/agent
          export CALLS=$TMPDIR/missing.calls
          ${lib.getExe personalOmp.reconcileHerdrOmp}
          test "$(cat "$CALLS")" = "integration install omp"
          test -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"

          export OMP_AGENT_DIR=$TMPDIR/current/agent
          mkdir -p "$OMP_AGENT_DIR/extensions"
          touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
          export CALLS=$TMPDIR/current.calls
          STATUS= ${lib.getExe personalOmp.reconcileHerdrOmp}
          test "$(cat "$CALLS")" = "integration status --outdated-only"

          export OMP_AGENT_DIR=$TMPDIR/stale/agent
          mkdir -p "$OMP_AGENT_DIR/extensions"
          touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
          export CALLS=$TMPDIR/stale.calls
          STATUS='omp: outdated (v7)' ${lib.getExe personalOmp.reconcileHerdrOmp}
          test "$(cat "$CALLS")" = "integration status --outdated-only
          integration install omp"

          touch $out
        '';

        # Defined once for the whole fleet in the plugin flake, which this
        # configuration already tracks, so the workstation validates its
        # artifacts exactly as every repository does.
        openspecContracts = inputs.personal-omp-plugin.lib.openspecCheck {
          inherit pkgs;
          src = ../.;
          name = "check-openspec-contracts";
        };

        windowsConfiguration = windowsConfigurationCheck;

      }
      // onNixosHost {
        wslOpenCommand = wslOpenCommandTest;

        # The host build is a check, so a host that stops building appears
        # in review rather than during activation.
        korolevSystem = korolevConfig.system.build.toplevel;

        # Keep OMP's browser mutable while supplying its foreign-binary ABI
        # from the rollback-safe NixOS generation.
        ompBrowserRuntime = ompBrowserRuntimeCheck;

        # The portable user modules have to build for Linux, not only
        # evaluate. This is the complete set that the WSL host selects.
        korolevHomeGeneration = korolevHome.home.activationPackage;

        # The dedicated outbound builder credential permits no inbound service.
        korolevIsolation =
          assert !korolevConfig.services.openssh.enable;
          assert korolevConfig.networking.firewall.allowedTCPPorts == [ ];
          assert korolevConfig.networking.firewall.allowedUDPPorts == [ ];
          assert !(korolevConfig ? sops);
          assert korolevConfig.services.tailscale.enable;
          assert !korolevConfig.services.tailscale.openFirewall;
          assert korolevConfig.services.tailscale.disableTaildrop;
          assert korolevConfig.services.tailscale.extraSetFlags == [ "--shields-up" ];
          assert korolevConfig.nix.distributedBuilds;
          assert builtins.length korolevBuildMachines == 1;
          assert korolevBuildMachine.hostName == "macbook-pro";
          pkgs.runCommand "check-wsl-host-isolation" { } "touch $out";

        # WSL 2 is already the virtual machine, so the runtime needs no
        # second one, and it exposes no socket another host could reach.
        # A Windows container product is not expressible here: Intune owns
        # Docker Desktop, and review covers that boundary.
        korolevContainerRuntime =
          assert korolevConfig.virtualisation.podman.enable;
          assert korolevConfig.virtualisation.podman.dockerCompat;
          assert !korolevConfig.virtualisation.podman.dockerSocket.enable;
          assert !korolevConfig.virtualisation.docker.enable;
          assert !korolevConfig.virtualisation.libvirtd.enable;
          pkgs.runCommand "check-wsl-host-container-runtime" { } "touch $out";

        # A login shell that the portable set does not configure would read
        # none of its own configuration, because that set generates no bash
        # files at all. `environment.shells` holds binary paths, so the
        # comparison is a prefix of the declared shell's store path.
        korolevLoginShell =
          assert korolevHome.programs.zsh.enable;
          assert korolevShell.pname == "zsh";
          assert builtins.any (
            entry: lib.hasPrefix (toString korolevShell) (toString entry)
          ) korolevConfig.environment.shells;
          pkgs.runCommand "check-wsl-host-login-shell" { } "touch $out";
      }
      // onDarwinHost {
        airBatchCommand = airBatchCommandTest;
        airBatchConfiguration = airBatchConfigCheck;
        containerRuntimeCommand = containerRuntimeCommandTest;
        containerRuntimeConfiguration = containerRuntimeConfigCheck;

        macbookProTailnet =
          let
            darwinConfig = self.darwinConfigurations.macbook-pro.config;
            username = darwinConfig.host.username;
            authorizedKeysFile = "/var/lib/tailnet-sshd/authorized_keys/${username}";
            sshdConfig = darwinConfig.environment.etc."ssh/sshd_config_tailnet".text;
            sshdArguments = darwinConfig.launchd.daemons.tailnet-sshd.serviceConfig.ProgramArguments;
            activation = darwinConfig.system.activationScripts.extraActivation.text;
          in
          assert darwinConfig.services.tailscale.enable;
          assert darwinConfig.services.tailscale.extraSetFlags == [ "--ssh=false" ];
          assert darwinConfig.services.openssh.enable == false;
          assert lib.elem username darwinConfig.determinateNix.customSettings.trusted-users;
          assert !(builtins.hasAttr "ssh/authorized_keys.d/${username}" darwinConfig.environment.etc);
          assert lib.hasInfix "AuthorizedKeysFile ${authorizedKeysFile}" sshdConfig;
          assert lib.hasInfix "StrictModes yes" sshdConfig;
          assert lib.hasInfix "/usr/bin/install -o root -g wheel -m 0444" activation;
          assert lib.hasInfix authorizedKeysFile activation;
          assert !(lib.elem "-e" sshdArguments);
          pkgs.runCommand "check-macbook-pro-tailnet" { } "touch $out";

        darwinSystem = self.darwinConfigurations.macbook-pro.system;
      };
    };
}
