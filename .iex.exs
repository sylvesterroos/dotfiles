IEx.configure(
  inspect: [
    pretty: true,
    limit: :infinity,
    syntax_colors: IO.ANSI.syntax_colors(),
    width: 80,
    # don't interpret lists of codepoints as charlists
    charlists: :as_lists
  ]
)
