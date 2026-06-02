# Based on https://github.com/RGBCube/ncc/blob/dentride/modules/web-browser.mod.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.my.web-browser;

  inherit (builtins) attrNames fromJSON readFile;

  mkExtension = id: {
    inherit id;
  };

  ublockAssets = fromJSON (readFile "${inputs.ublock}/assets/assets.json");

  ublockFilterLists =
    filter (
      name:
      name != "ublock-experimental"
      && (ublockAssets.${name}.content or null) == "filters"
      && (ublockAssets.${name}.group or null) != "regions"
    ) (attrNames ublockAssets)
    ++ [
      "TUR-0"
      "user-filters"
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/BrowseWebsitesWithoutLoggingIn.txt"
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/ClearURLs%20for%20uBo/clear_urls_uboified.txt"
      "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt"
      "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/annoyance_list.txt"
      "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/click2load.txt"
      "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/privacy_essentials.txt"
    ];

  ublockFilters = [
    ''||youtube.com/shorts/$document,uritransform=/^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/([^\/?#]+)/https:\/\/www.youtube.com\/watch?v=\$1/''
    "@@||reddit.com/media$document"
    "@@||reddit.com/mod$document"
    "@@||reddit.com/poll$document"
    "@@||reddit.com/settings$document"
    "@@||reddit.com/topics$document"
    "@@||reddit.com/community-points$document"
    "@@||reddit.com/appeal$document"
    "@@||reddit.com/appeals$document"
    "@@||reddit.com/notifications$document"
    "@@||reddit.com/message/compose/$document"
    "@@||reddit.com/mail^$document"
    "@@||reddit.com/answers^$document"
    "@@||reddit.com/r/subreddit^$document"
    ''@@/^https:\/\/\w*\.?reddit\.com\/r\/[A-Za-z0-9_]+\/s\//$document''
    ''@@/^https:\/\/\w*\.?reddit\.com\/.*[?&]new_reddit=true(?:$|[&#])/$document''
    ''||reddit.com/gallery/$document,uritransform=/^https:\/\/(?:www\.|np\.|amp\.|i\.)?reddit\.com\/gallery\/(.*)/https:\/\/old.reddit.com\/comments\/\$1/''
    ''||reddit.com^$document,uritransform=/^https:\/\/(?:www\.|np\.|amp\.|i\.)?reddit\.com\/(?!gallery\/)/https:\/\/old.reddit.com\//''
    "old.reddit.com##:is(#eu-cookie-policy, #redesign-beta-optin-btn)"
  ];

  extensions = {
    augmented-steam = mkExtension "dnhpnfgdlenaccegplpojghhmaamnnfp";
    consent-o-matic = mkExtension "mdjildafknihdffpkfmmpnpoiajfjnjd";
    dearrow = mkExtension "enamippconapkdmgfgjchkhakpfinmaj";
    livedebugger-devtools = mkExtension "gmdfnfcigbfkmghbjeelmbkbiglbmbpe";
    mega = mkExtension "bigefpfhnfcobdlfbedofhhaibnlghod";
    obsidian-web-clipper = mkExtension "cnjifjpddelmedmihgijeibhnjfabmlf";
    proton-pass = mkExtension "ghmbeldphafepmbegfdlkpapadhbakde";
    quillbot = mkExtension "iidnbdjijdkbmajdffnidomddglmieko";
    refined-github = mkExtension "hlepfoohegkhhmjieoechaddaejaokhf";
    return-youtube-dislike = mkExtension "gebbhagfogifgggkldgodflihgfeippi";
    sponsorblock = mkExtension "mnjggcdmjocbbbhaepdhchncahnbgone";

    ublock-origin = {
      id = "blockjmkbacgjkknlgpkjjiijinjdanf";
      preinstalled = true;
      settings.toolbar_pin = "force_pinned";
      policy = {
        toOverwrite = {
          filterLists = ublockFilterLists;
          filters = ublockFilters;
        };
        userSettings = [
          [
            "userFiltersTrusted"
            "true"
          ]
        ];
      };
    };
  };

  extensionIds =
    extensions
    |> filterAttrs (_: extension: !(extension.preinstalled or false))
    |> mapAttrsToList (_: extension: extension.id);

  extensionSettings =
    extensions
    |> concatMapAttrs (
      _: extension: optionalAttrs (extension ? settings) { ${extension.id} = extension.settings; }
    );

  extensionPolicies =
    extensions
    |> concatMapAttrs (
      _: extension: optionalAttrs (extension ? policy) { ${extension.id} = extension.policy; }
    );

  policy = {
    ExtensionInstallBlocklist = [ "*" ];
    ExtensionInstallAllowlist = extensionIds;
    ExtensionInstallForcelist = extensionIds;
    ExtensionInstallSources = [ "https://services.helium.imput.net/*" ];
    ExtensionSettings = extensionSettings;
    "3rdparty".extensions = extensionPolicies;

    DefaultBrowserSettingEnabled = false;
    DeveloperToolsAvailability = 1;
    RestoreOnStartup = 1;

    SearchSuggestEnabled = true;
  };

  preferences = {
    helium.completed_onboarding = true;
    helium.services.user_consented = true;
    helium.browser.layout = 2;
    helium.browser.rounded_frame = false;
    helium.browser.new_tab_next_to_active = true;

    bookmark_bar.show_on_all_tabs = true;
    bookmark_bar.show_tab_groups = false;
    download.prompt_for_download = true;
  };

  mimeTypes = [
    "application/pdf"
    "application/rdf+xml"
    "application/rss+xml"
    "application/xhtml+xml"
    "application/xhtml_xml"
    "application/xml"
    "image/gif"
    "image/jpeg"
    "image/png"
    "image/webp"
    "text/html"
    "text/xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];
in
{
  options.my.web-browser = {
    enable = mkEnableOption "web browser" // {
      default = pkgs.stdenv.isLinux;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "my.web-browser currently only supports Linux Home Manager hosts.";
      }
    ];

    home.packages = [ inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    xdg.configFile = {
      "helium/Default/Preferences".text = builtins.toJSON preferences;
      "chromium/policies/managed/helium.json".text = builtins.toJSON policy;
    };

    xdg.mimeApps.defaultApplications = genAttrs mimeTypes (_: "helium.desktop");
  };
}
