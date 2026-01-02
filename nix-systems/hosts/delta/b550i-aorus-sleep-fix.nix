{
  pkgs,
  lib,
  ...
}: {
  # https://wiki.archlinux.org/title/Power_management/Wakeup_triggers#GPP_bridge
  systemd.services.wakeup-disable_GPP0 = {
    enable = true;
    description = "Fix B550i Aorus suspend by disabling the GPP bridge to the NVMe drive";
    serviceConfig = {
      ExecStart = ''${lib.getExe pkgs.bash} -c "echo GPP0 >> /proc/acpi/wakeup"'';
    };
    wantedBy = ["multi-user.target"];
  };
}
