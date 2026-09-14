{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };

    # 👇 ADD THIS BLOCK RIGHT HERE 👇
    fonts.packages = [
      pkgs.jetbrains-mono              # The clean, official IntelliJ font
      pkgs.nerd-fonts.jetbrains-mono   # The same font, but patched with developer icons/glyphs
    ];

    environment.systemPackages = [
      pkgs.adwaita-icon-theme
    ];

    environment.variables = {
      XCURSOR_SIZE = "16";
      XCURSOR_THEME = "Adwaita";

      # Forces Java apps to use smooth, crisp font anti-aliasing
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.uiScale=1.5";
    };
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!

      env = {
         GBM_BACKEND = "nvidia-drm";
         __GLX_VENDOR_LIBRARY_NAME = "nvidia";
         WLR_NO_HARDWARE_CURSORS = "1";
         ELECTRON_OZONE_PLATFORM_HINT = "auto";
         XCURSOR_SIZE = "16";
         XCURSOR_THEME = "Adwaita";

        _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.uiScale=1.5";
      };

      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)

          # 👇 ADD THIS LINE 👇
          [ "sh" "-c" "sleep 3 && wpctl set-default $(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -i 'Arctis' | grep -oE '[0-9]+' | head -n1)" ]
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
        input.keyboard.xkb.layout = "us,ua";

        layout.gaps = 15; # Gap between windows in workspace
        layout.struts.left = 25; # Left gap between Noctalia and my workspace

        # 👇 ADD THIS BLOCK RIGHT HERE 👇
        cursor = {
          xcursor-size = 16; # Standard sizes are 16, 24, 32. 16 is nice and small.
          xcursor-theme = "Adwaita";
        };

        # 1. 👇 ADD THIS LINE HERE to tell Niri where to save screenshots on disk
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        # --- 1. Fix: Disable Mouse Hot Corners (Top edge overview/workspace trigger) ---
        gestures.hot-corners.off = {};

        # --- MONITOR LAYOUT CONFIGURATION ---
        # Note: "outputs" must be plural for nix-wrapper-modules to generate KDL correctly
        outputs = {
          # 1. Your Full HD monitor on the LEFT
          # (Replace with your actual left monitor name from 'niri msg outputs')
          "DP-3" = {
            mode = "1920x1080@60.000"; # Adjust refresh rate if yours is higher
            position = _: { props = { x = 0; y = 0; }; };
          };

          # 2. Your 2K Main Monitor in the CENTER
          "HDMI-A-4" = {
            mode = "2560x1440@144.000"; # Adjust to your actual refresh rate (e.g., 144, 165, 240)
            position = _: { props = { x = 1920; y = 0; }; };
          };
        };

        input.focus-follows-mouse = _: { props = { max-scroll-amount = "0%"; }; };

        # --- Fixed Binds Block ---
        binds = ( {
          "Mod+Q".spawn = ["kitty"];
          "Mod+Space".spawn = [ "sh" "-c" "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle" ];
          "Mod+C".close-window = {};
          "Mod+B".spawn = [ "brave" ];

          # --- Horizontal Navigation (Between Columns) ---
          "Mod+Left".focus-column-left = {};
          "Mod+Right".focus-column-right = {};

          # --- Vertical Navigation (Within a Stacked Column) ---
          "Mod+Up".focus-window-up = {};
          "Mod+Down".focus-window-down = {};

          # --- Moving Columns Horizontally ---
          "Mod+Shift+Left".move-column-left = {};
          "Mod+Shift+Right".move-column-right = {};

          # --- Moving Windows Vertically ---
          "Mod+Shift+Up".move-window-up = {};
          "Mod+Shift+Down".move-window-down = {};

          # --- Column Stacking (The Bracket Bindings) ---
          "Mod+bracketleft".consume-or-expel-window-left = {};
          "Mod+bracketright".consume-or-expel-window-right = {};

          # --- Quick Resizing ---
          "Mod+R".switch-preset-column-width = {};
          "Mod+F".maximize-column = {};

          "Print".screenshot = {};
          "Ctrl+Print".screenshot-screen = {};
          "Alt+Print".screenshot-window = {};
        }
        # Merges the 1-9 workspace switching and window moving shortcuts
        // (builtins.listToAttrs (builtins.concatLists (builtins.genList (i:
          let
            ws = i + 1;
            wsStr = toString ws;
          in [
            # Super + Number to switch workspace
            {
              name = "Mod+${wsStr}";
              value.focus-workspace = ws;
            }
            # Super + Shift + Number to send the current window to that workspace
            {
              name = "Mod+Shift+${wsStr}";
              value.move-column-to-workspace = ws;
            }
          ]
        ) 9))) );
      };
    };
  };
}
