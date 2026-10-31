# The framework's touchpad clicks by pressing the pad only.
{
  flake.modules.homeManager.framework.programs.plasma.input.touchpads = [
    {
      name = "PIXA3854:00 093A:1343 Touchpad";
      vendorId = "093a";
      productId = "1343";
      tapToClick = false;
    }
  ];
}
