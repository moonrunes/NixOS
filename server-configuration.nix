{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <nixpkgs/nixos/modules/profiles/headless.nix>
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernel.sysctl = { "vm.swappiness" = 10;};
  boot.supportedFilesystems = [ "btrfs" ];

  networking = {
    hostName = "hostname";           # Change me
    interfaces = {
      enp1s0 = {                     # Change me
        useDHCP = false;
        ipv4.addresses = [ {
          address = "x.x.x.x";       # Change me
          prefixLength = 20;
        } ];
      };
    };
    defaultGateway = "10.10.10.1";
    nameservers = [ "10.10.10.1" ];
  };

  time.timeZone = "America/Chicago";

  environment.shellAliases = {
    ".."="cd ..";
    "..."="cd ../..";
    "...."="cd ../../..";
    "....."="cd ../../../..";
    ll="ls -alF";
    la="ls -A";
    l="ls -CF";
    cp="cp -i"; 
    df="df -h";
    free="free -m";
    more="less";
  };

  users.groups = {
    sshusers = { 
      gid = 1001;
    };
  };
  users.users.nick = {
    isNormalUser = true;
    description = "Nick";
    openssh.authorizedKeys.keyFiles = [ "/etc/ssh/authorized_keys.d/nick" ];
    extraGroups = [ "networkmanager" "wheel" "sshusers" "docker" ];
    packages = with pkgs; [];
  };

  security.doas.enable = true;
  security.sudo.enable = false;
  security.sudo.execWheelOnly = true;
  security.doas.extraRules = [{
    groups = ["wheel"];
    keepEnv = true;  # Optional, retains environment variables while running commands
    persist = true;  # Optional, only require password verification a single time
  }];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    btop
    doas
    doas-sudo-shim
    docker-compose
    dua
    e2fsprogs
    hddtemp
    iotop
    lm_sensors
    mergerfs
    mc
    nano
    ncdu
    neofetch
    nmap
    nvme-cli
    parted
    smartmontools
    snapraid
    rng-tools
    rsync
    sshfs
    tmux
    tree
    vim
    wget
  ];

  programs.bash = {
    interactiveShellInit = "neofetch";
    promptInit = ''
      if [ "$color_prompt" = yes ]; then
        PS1+='\e[1;36m\u' 	#username
        PS1+='\e[0m@' 			#at
        PS1+='\e[1;36m\h'		#hostname
        PS1+='\e[0m:'			  #colon
        PS1+='\e[1;36m\w'		#working directory
        PS1+='\e[0m\n\\$ '	#reset newline prompt
        PS2='\e[0m> '				#subprompt
      else
        PS1='\u@\h:\w\n\$ '
        PS2='> '
      fi
    '';
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    newSession = true;
    escapeTime = 0;
    clock24 = true;
    extraConfig = ''
      # Remove original prefix binding
      unbind C-b

      # Fix colors
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"  
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Enable mouse control (clickable windows, panes, resizable panes)
      set-option -g mouse on

      # Don't rename windows automatically
      set-option -g allow-rename off

      # Initialize session
      new  -n WindowName Command
      neww
      split -v -p 50 -t 0 
      split -h -p 70 -t 0 btop
      split -h -p 50 -t 2 mc
      selectw -t 0
      selectp -t 0
    '';
  };

  services.btrfs.autoScrub.enable = true;

  services.openssh = {
    enable = true;
    allowSFTP = true;
    extraConfig = ''
      AuthenticationMethods publickey
      Protocol 2
      PermitUserEnvironment no
      AllowTcpForwarding no
      AllowStreamLocalForwarding no
      PermitTunnel no
      PermitEmptyPasswords no
      IgnoreRhosts yes
      Compression no
      TCPKeepAlive no
      AllowAgentForwarding no
      HostbasedAuthentication no
      ClientAliveCountMax 0
      ClientAliveInterval 300
      LoginGraceTime 60
      MaxAuthTries 4
      MaxSessions 4
      MaxStartups 4
    '';
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
    openFirewall = true;
    settings = {
      AllowGroups = [ "sshusers" ];
      LogLevel = "VERBOSE";
      GatewayPorts = "no";
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      UseDns = false;
      X11Forwarding = false;
    };
    sftpFlags = [
      "-f AUTHPRIV"
      "-l INFO"
    ];
    sftpServerExecutable = "internal-sftp";
  };

  services.tailscale.enable = true;

# virtualisation = {
#   docker = {
#     enable = true;
#     autoPrune = {
#       enable = true;
#       dates = "weekly";
#     };
#   };
# };

# systemd.services.my-docker-compose = {
#   script = ''
#     docker-compose -f ${./path-to/docker-compose.yml}
#   '';
#   wantedBy = ["multi-user.target"];
#   after = ["docker.service" "docker.socket"];
# };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.copySystemConfiguration = true;
  system.stateVersion = "23.05"; # Did you read the comment?

  # Auto system update
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = "https://channels.nixos.org/nixos-23.11-small";
  };

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
