{ self, inputs, ... }: {

  flake.nixosModules.myMachineConfiguration = { pkgs, lib, config, ... }: {
    imports = [
      self.nixosModules.myMachineHardware
      self.nixosModules.niri
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Fix: Allow auto-downloaded binaries (like Zed LSPs) to run on NixOS
    programs.nix-ld.enable = true;

    # Fix: Allow the proprietary NVIDIA drivers to build
    nixpkgs.config.allowUnfree = true;

    programs.git = {
      enable = true;
      config = {
        user = {
          name = "BlackGM16";
          email = "ltezycki@gmail.com";
        };
      };
    };

    # Fix: For java project
    environment.sessionVariables = {
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

    environment.variables = {
      LD_LIBRARY_PATH = "${pkgs.gtk3}/lib:${pkgs.glib}/lib:${pkgs.mesa}/lib:${pkgs.libGL}/lib";
    };

    # Bootloader config
    boot.loader.systemd-boot.enable = false;
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    # Fix: REMOVED "nomodeset" so Wayland/Niri can actually start
    boot.kernelParams = [ "nvidia-drm.modeset=1" ];

    # Fix: Setup proper NVIDIA drivers for Wayland
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.graphics.enable = true;
    hardware.nvidia = {
      modesetting.enable = true; # Required for Niri/Wayland
      powerManagement.enable = true;
      open = true;              # Set to true if you have a GTX 1660 / RTX 2000 or newer
    };

    networking.hostName = "nixos-btw";
    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Warsaw";

    # Fix: Enable GDM (Login Screen) to manage your Wayland session
    services.xserver.enable = true; # Keep this enabled for XWayland compatibility
    # Clean and compatible with GNOME 50+
    #services.displayManager.gdm.enable = true;

    #environment.pathsToLink = ["/share/gnome-sessions"];
   # environment.sessionVariables.XDG_DATA_DIRS = [ "${pkgs.gdm}/share" ];
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = false;

#    services.displayManager.sessionPackages = let
 #      sys = pkgs.stdenv.hostPlatform.system;
  #     wrappedNiri = self.packages.${sys}.myNiri;
   # in [
#	((pkgs.writeTextDir "share/wayland-sessions/niri.desktop" ''
#	  [Desktop Entry]
#	  Name=Niri (Wrapped)
 #	  Comment=A scrollable-tiling Wayland compositor
#	  Exec=${wrappedNiri}/bin/niri
#	  Type=Application
#	  DesktopNames=niri
#	'') // { providedSessions = [ "niri" ]; })
 #   ];

   # services.displayManager.sessionPackages = [ pkgs.niri ];

    users.users.lukmon = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      packages = with pkgs; [ tree ];
    };

    programs.firefox.enable = true;

    # Paste it right here:
    programs.java = {
      enable = true;
      package = pkgs.jdk25; # Can change to jdk25 or any version you need
    };

    environment.systemPackages = with pkgs; [
      vim
      wget
      alacritty
      efibootmgr
      zed-editor
      brave
      gnome-session
      kitty
      obsidian
      git
      maven
      gradle
      jetbrains.idea
      zenity

      mesa
      libGL
      glib
      gtk3
    ];

    programs.nix-ld.libraries = with pkgs; [
      gtk3
      libGL
      mesa
      glib
   ];

    system.stateVersion = "26.05";
  };
}
