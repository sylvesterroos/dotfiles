{ ... }:
{
  enable = true;
  keyboards = {
    capsToEscCtrl = {
      # do not specify `devices` to use all keyboards
      # devices = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
      extraDefCfg = "process-unmapped-keys yes";
      config = # lisp
        ''
          (defsrc
           caps
          )
          (defalias
           escctrl (tap-hold 250 250 esc lctrl)
          )
          (deflayer base
            @escctrl
          )
        '';
    };
  };
}
