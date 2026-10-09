{
  flake.modules.nixos.desktop = {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    users.users.sylvester.extraGroups = [ "audio" ];
  };

  flake.modules.homeManager.desktop = {
    services.easyeffects = {
      enable = true;
      preset.input = "microphone";
      settings = {
        EffectsPipelines = {
          processAllInputs = true;
          processAllOutputs = false;
          bypass = false;
        };
        StreamInputs = {
          useDefaultInputDevice = true;
          listenToMic = false;
        };
        Window.autostartOnLogin = false;
      };

      # Starting points for speech; thresholds depend on microphone gain and room noise.
      extraPresets.microphone.input = {
        blocklist = [ ];
        plugins_order = [
          "filter#0"
          "expander#0"
          "deesser#0"
          "equalizer#0"
          "compressor#0"
          "limiter#0"
        ];

        "filter#0" = {
          bypass = false;
          type = "High-pass";
          mode = "BWC (BT)";
          equal-mode = "IIR";
          slope = "x2";
          decramp = "Off";
          frequency = 80.0;
        };

        "expander#0" = {
          bypass = false;
          mode = "Downward";
          threshold = -45.0;
          ratio = 2.0;
          knee = -6.0;
          attack = 5.0;
          release = 150.0;
          hpf-mode = "Off";
          lpf-mode = "Off";
          sidechain = {
            type = "Internal";
            mode = "RMS";
            source = "Middle";
            stereo-split-source = "Left/Right";
          };
        };

        "deesser#0" = {
          bypass = false;
          detection = "RMS";
          mode = "Split";
          threshold = -18.0;
          ratio = 3.0;
          f1-freq = 6000.0;
          f2-freq = 4500.0;
          f2-level = 6.0;
        };

        "equalizer#0" =
          let
            bands = {
              band0 = {
                type = "Bell";
                mode = "RLC (BT)";
                slope = "x1";
                frequency = 250.0;
                gain = -2.0;
                q = 1.0;
              };
              band1 = {
                type = "Bell";
                mode = "RLC (BT)";
                slope = "x1";
                frequency = 3000.0;
                gain = 1.5;
                q = 1.0;
              };
            };
          in
          {
            bypass = false;
            mode = "IIR";
            decramp = "Off";
            num-bands = 2;
            split-channels = false;
            left = bands;
            right = bands;
          };

        "compressor#0" = {
          bypass = false;
          mode = "Downward";
          threshold = -18.0;
          ratio = 3.0;
          knee = -6.0;
          attack = 10.0;
          release = 100.0;
          makeup = 3.0;
          hpf-mode = "Off";
          lpf-mode = "Off";
          sidechain = {
            type = "Feed-forward";
            mode = "RMS";
            source = "Middle";
            stereo-split-source = "Left/Right";
          };
        };

        "limiter#0" = {
          bypass = false;
          mode = "Herm Thin";
          oversampling = "None";
          dithering = "None";
          sidechain-type = "Internal";
          threshold = -1.0;
          gain-boost = false;
          lookahead = 5.0;
          attack = 5.0;
          release = 20.0;
        };
      };
    };
  };
}
