# Wine's application icon in hicolor, for desktop entries that name
# `Icon=wine` (protontricks, wine.desktop). The wine package ships the
# desktop entry without the icon.
{
  runCommand,
  wine,
}:

runCommand "wine-icon-${wine.version}" { } ''
  tar --extract --file ${wine.src} --strip-components=3 \
    wine-${wine.version}/dlls/wineandroid.drv/wine.svg
  install -D --mode=0644 wine.svg $out/share/icons/hicolor/scalable/apps/wine.svg
''
