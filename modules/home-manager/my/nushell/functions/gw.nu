def assert-git [] {
  let is_git = do { git rev-parse --is-inside-work-tree } | complete
  match $is_git.exit_code {
    0 => { }
    _ => { error make {msg: "Not in a git directory"} }
  }
}

def parse-worktrees [] {
  git worktree list --porcelain
  | split row "\n\n"
  | each {
    lines
    | parse "{type} {value}"
    | transpose -r -i
  }
  | flatten
  | update branch { str replace 'refs/heads/' '' }
}

# Switch between git worktrees
def --env gw [] {
  assert-git
  let worktrees = parse-worktrees
  let selected = try {
    $worktrees | input list --fuzzy --display branch "Select worktree:"
  } catch {|err|
    match ($err.json | from json | get code?) {
      "nu::shell::io::interrupted" => { return }
      _ => { error make {msg: $err.msg} }
    }
  }
  cd $selected.worktree
}

# Add a new git worktree from a local or remote branch
def --env "gw add" [
  --base: string = "develop"
] {
  assert-git
  git fetch --prune origin
  let worktrees = parse-worktrees
  let base = $worktrees | where branch == $base | first
  if ($base | is-empty) { error make {msg: $"No ($base) worktree found"} }
  let remote_branches = git branch -r
    | lines
    | str trim
    | where { $in !~ 'HEAD' }
    | each { str replace 'origin/' '' }
  let local_branches = git branch
    | lines
    | str trim
    | where { not ($in | str starts-with '*') }
  let existing = $worktrees | get branch | uniq
  let branches = $remote_branches | append $local_branches | uniq | where { $in not-in $existing }
  let selected = try {
    $branches | input list --fuzzy "Select branch:"
  } catch {|err|
    match ($err.json | from json | get code?) {
      "nu::shell::io::interrupted" => { return }
      _ => { error make {msg: $err.msg} }
    }
  }
  let worktree_path = $base.worktree | path dirname | path join $selected
  git worktree add $worktree_path $selected
  cd $worktree_path
}

# Remove worktrees whose branch no longer exists on the remote
def "gw prune" [] {
  assert-git
  git fetch --prune origin
  let remote_branches = git branch -r
    | lines
    | str trim
    | where { not ($in | str contains "->") }
    | each { str replace 'origin/' '' }
  let stale = parse-worktrees | where { $in.branch not-in $remote_branches }
  if ($stale | is-empty) {
    print "No stale worktrees found."
    return
  }
  print $"Found ($stale | length) stale worktree\(s\):"
  print ($stale | select worktree branch)
  let confirm = try {
    input "Delete these worktrees? [y/N] " | str trim | str downcase
  } catch {|err|
    match ($err.json | from json | get code?) {
      "nu::shell::io::interrupted" => { return }
      _ => { error make {msg: $err.msg} }
    }
  }
  match $confirm {
    "y" => { }
    _ => { print "Aborted."; return }
  }
  for wt in $stale {
    let result = do { git worktree remove $wt.worktree } | complete
    match $result.exit_code {
      0 => { print $"  Removed ($wt.branch)" }
      _ => { print $"  Failed to remove ($wt.branch): ($result.stderr | str trim)" }
    }
  }
}
