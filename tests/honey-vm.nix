{ pkgs, inputs, desktopPkgs, unstablePkgs, compositor, requireCapture ? true }:
let
  niriTestSession = pkgs.writeShellScript "honey-niri-vm-session" ''
    mkdir -p "$HOME/.local/state"
    ${pkgs.weston}/bin/weston --backend=drm --renderer=pixman --socket=honey-test-parent --idle-time=0 > "$HOME/.local/state/honey-test-weston.log" 2>&1 &
    weston_pid=$!
    trap 'kill "$weston_pid" 2>/dev/null || true' EXIT
    for attempt in $(seq 1 100); do
      test -S "$XDG_RUNTIME_DIR/honey-test-parent" && break
      sleep .1
    done
    export WAYLAND_DISPLAY=honey-test-parent XDG_CURRENT_DESKTOP=niri XDG_SESSION_TYPE=wayland
    ${unstablePkgs.niri}/bin/niri
  '';
  command = if compositor == "niri" then "${niriTestSession}"
    else "${desktopPkgs.hyprland}/bin/start-hyprland";
in pkgs.testers.runNixOSTest {
  name = "honey-${compositor}";
  node.specialArgs = { inherit inputs desktopPkgs unstablePkgs; };
  nodes.machine = { config, lib, pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ../modules/desktop/${compositor}.nix ]
      ++ lib.optional (compositor == "pleamar") inputs.pleamar-wm.nixosModules.default;
    virtualisation = { graphics = true; qemu.options = [ "-vga none -device virtio-gpu-pci" "-display none" ]; memorySize = 4096; cores = 4; resolution = { x = 1920; y = 1080; }; };
    hardware.graphics.enable = true;
    environment.systemPackages = [ inputs.pleamar-wm.inputs.pleamar.packages.${pkgs.stdenv.hostPlatform.system}.pleamar pkgs.wayland-utils pkgs.jq pkgs.libnotify pkgs.wl-clipboard pkgs.procps pkgs.kitty ];
    services.pipewire = { enable = true; pulse.enable = true; };
    security.rtkit.enable = true;
    services.greetd = {
      enable = true;
      settings = {
        initial_session = { user = "geko"; command = if compositor == "pleamar" then "${config.programs.pleamar-wm.package}/bin/pleamar-wm-session" else command; };
        default_session = { user = "geko"; command = "${pkgs.coreutils}/bin/sleep infinity"; };
      };
    };
    users.users.geko = { isNormalUser = true; uid = 1000; password = "honeytest"; extraGroups = [ "video" "input" ]; };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.geko = {
        home.username = "geko";
        home.homeDirectory = "/home/geko";
        home.stateVersion = "26.05";
        xdg.enable = true;
        programs.honeyShell.settings.motion.reduced = true;
      };
    };
    system.stateVersion = "26.05";
  };
  testScript = ''
    import shlex
    import json
    import time
    import os
    start_all()
    machine.wait_for_unit("greetd.service")
    def user(command):
        command=command.replace("pleamar --say", "timeout 5 pleamar --say").replace("pleamar-wm --say", "timeout 5 pleamar-wm --say")
        return "su - geko -c " + shlex.quote("export XDG_RUNTIME_DIR=/run/user/1000; export PATH=/etc/profiles/per-user/geko/bin:$PATH; export WAYLAND_DISPLAY=$(systemctl --user show-environment | sed -n 's/^WAYLAND_DISPLAY=//p'); export NIRI_SOCKET=$(systemctl --user show-environment | sed -n 's/^NIRI_SOCKET=//p'); export HYPRLAND_INSTANCE_SIGNATURE=$(systemctl --user show-environment | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p'); " + command)
    try:
        machine.wait_until_succeeds(user("systemctl --user is-active honey-shell.service"),timeout=90)
    except Exception:
        print(machine.execute("journalctl -b --no-pager -u greetd; cat /home/geko/.local/state/pleamar-wm/session.log; cat /home/geko/.local/state/honey-test-weston.log; ls -l /dev/dri"))
        print(machine.execute(user("journalctl --user -b --no-pager; cat ~/.local/state/hyprland/hyprland.log")))
        raise
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel'"),timeout=120)
    machine.succeed(user("honeyctl session"))
    machine.succeed("! pgrep -x marea")
    machine.succeed(user("PLEAMAR_SOCKETS=/run/user/1000/other-scene honeyctl open launcher"))
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel' | grep -q 1"))
    time.sleep(2)
    machine.screenshot("${compositor}-launcher")
    machine.succeed(user("honeyctl toggle clipboard"))
    machine.succeed(user("honeyctl open controls"))
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel' | grep -q 2"),timeout=60)
    time.sleep(1)
    machine.screenshot("${compositor}-controls")
    machine.succeed(user("honeyctl toggle close"))
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel' | grep -q 0"))
    machine.succeed(user("systemctl --user restart honey-shell.service"))
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel'"))
    machine.succeed(user("systemctl --user show honey-shell -p MainPID --value | xargs -r kill -0"))
    machine.succeed(user("systemctl --user is-active honey-wallpaper.service honey-notifications.service honey-polkit.service honey-reserve.service"))
    machine.succeed(user("notify-send Honey 'Teste isolado'"))
    time.sleep(1)
    machine.screenshot("${compositor}-idle")
    machine.succeed(user("systemd-run --user --unit honey-test-app --collect kitty"))
    if "${compositor}" == "niri":
        machine.wait_until_succeeds(user("niri msg -j windows | jq -e 'length > 0'"),timeout=60)
    elif "${compositor}" == "hyprland":
        machine.wait_until_succeeds(user("hyprctl -j clients | jq -e 'length > 0'"),timeout=60)
    else:
        machine.wait_until_succeeds(user("pleamar-wm --say session 'get win.count' | grep -q 1"),timeout=60)
    time.sleep(3)
    if "${compositor}" == "hyprland":
        clients=json.loads(machine.succeed(user("hyprctl -j clients")))
        assert clients[0]["at"][1] >= 80, "Honey top reserve was not applied"
    elif "${compositor}" == "pleamar":
        reserved=machine.succeed(user("pleamar-wm --say session 'get win.reserved.0.top'"))
        assert float(reserved.strip()) >= 80, "Honey top reserve was not applied"
    capture_status,capture_output=machine.execute(user("WAYLAND_DEBUG=1 honeyctl screenshot screen"),timeout=25)
    if capture_status:
        print("CAPTURE FAILURE:",capture_output)
        print(machine.execute("tail -80 /home/geko/.local/state/pleamar-wm/session.log"))
    else:
        machine.wait_until_succeeds("find /home/geko/Imagens/Capturas -name '*.png' | grep -q .",timeout=30)
        desktop_capture=machine.succeed("find /home/geko/Imagens/Capturas -name '*.png' | head -1").strip()
        machine.copy_from_vm(desktop_capture,"native-desktop")
    if "${compositor}" == "niri":
        machine.wait_until_succeeds(user("niri msg -j windows | jq -e 'length > 0'"))
        windows=json.loads(machine.succeed(user("niri msg -j windows")))
        assert len(windows)>0
        machine.succeed(user("niri msg action move-window-to-workspace 2; niri msg action focus-workspace 2; niri msg action fullscreen-window"))
        machine.execute(user("honeyctl screenshot screen"),timeout=25)
    elif "${compositor}" == "hyprland":
        machine.wait_until_succeeds(user("hyprctl -j clients | jq -e 'length > 0'"))
        assert machine.succeed(user("hyprctl configerrors")).strip()==""
        machine.succeed(user("hyprctl dispatch 'hl.dsp.window.move({workspace=2})'; hyprctl dispatch 'hl.dsp.focus({workspace=2})'; hyprctl dispatch 'hl.dsp.window.fullscreen()'"))
        machine.execute(user("honeyctl screenshot screen"),timeout=25)
    else:
        machine.wait_until_succeeds(user("pleamar-wm --say session 'get win.count' | grep -q 1"))
        machine.succeed(user("pleamar-wm --say session 'emit move_to_workspace 2'; pleamar-wm --say session 'emit workspace 2'; pleamar-wm --say session 'emit fullscreen'"))
        machine.execute(user("honeyctl screenshot screen"),timeout=25)
    machine.succeed(user("printf honey-clipboard-test | wl-copy"))
    machine.wait_until_succeeds("grep -q honey-clipboard-test /home/geko/.local/state/honey/history.json",timeout=30)
    machine.succeed(user("honeyctl clear-clipboard"))
    assert json.loads(machine.succeed("cat /home/geko/.local/state/honey/history.json")) == []
    machine.succeed(user("honeyctl lock"))
    machine.wait_until_succeeds("pgrep -u geko -x 'swaylock|\\.swaylock.*'")
    machine.screenshot("${compositor}-locked")
    machine.send_chars("honeytest")
    machine.send_key("ret")
    machine.wait_until_succeeds("! pgrep -u geko -x 'swaylock|\\.swaylock.*'",timeout=30)
    machine.succeed(user("systemctl --user stop honey-session.target"))
    machine.succeed(user("! systemctl --user is-active honey-shell.service"))
    machine.succeed(user("systemctl --user start honey-session.target"))
    machine.wait_until_succeeds(user("systemctl --user is-active honey-shell.service"))
    machine.wait_until_succeeds(user("pleamar --say honey 'get panel'"),timeout=90)
    time.sleep(3)
    if "${compositor}" == "niri":
        machine.execute(user("niri msg action quit --skip-confirmation"))
    elif "${compositor}" == "hyprland":
        machine.succeed(user("hyprctl dispatch 'hl.dsp.exit()'"))
    else:
        machine.succeed("systemctl stop greetd.service")
    machine.wait_until_succeeds("! pgrep -u geko -f /share/honey/src/honey.plm",timeout=30)
    machine.succeed("systemctl stop greetd.service")
    with open(os.environ["out"]+"/validation.json","w") as report:
        json.dump({"compositor":"${compositor}","capture_ok":capture_status==0,"session_tests_ok":True,"nested": "${compositor}"=="niri"},report)
    assert capture_status==0 or ${if requireCapture then "False" else "True"}, "Native capture failed; session checks completed."
  '';
}
