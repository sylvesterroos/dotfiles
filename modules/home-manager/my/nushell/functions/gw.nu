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
    | each { str replace -r '^origin/' '' }
  let local_branches = git branch
    | lines
    | str trim
    | where { $in != "" }
    | each { str replace -r '^[*+]\s+' '' }
  let existing_worktrees = $worktrees
    | where { $in.branch? != null and $in.branch? != "" }
    | select branch worktree
  let branches = $remote_branches
    | append $local_branches
    | append ($existing_worktrees | get branch)
    | where { $in != "" }
    | uniq
    | sort
  let selected = try {
    $branches | input list --fuzzy "Select branch:"
  } catch {|err|
    match ($err.json | from json | get code?) {
      "nu::shell::io::interrupted" => { return }
      _ => { error make {msg: $err.msg} }
    }
  }
  if ($selected | is-empty) { return }
  let existing = $existing_worktrees | where branch == $selected
  if not ($existing | is-empty) {
    let worktree_path = $existing | first | get worktree
    cd $worktree_path
    return
  }
  let worktree_path = $base.worktree | path dirname | path join $selected
  git worktree add $worktree_path $selected
  cd $worktree_path
}

# Remove worktrees whose branch was deleted from remote
def "gw prune" [] {
  assert-git
  git fetch --prune origin
  let branch_statuses = git branch -vv
    | lines
    | each {|line|
      # Rows can start with '*' (current) or '+' (checked out in another worktree).
      let normalized = $line
        | str trim
        | str replace -r '^[*+]\s+' ''
      let branch = ($normalized | split row -r '\s+' | get 0)
      let has_gone_marker = $line | str contains ": gone]"
      let has_tracking_info = $line | str contains "["
      let status = match [$has_gone_marker $has_tracking_info] {
        [true _] => { "deleted from remote" }
        [false true] => { "pushed" }
        _ => { "never pushed" }
      }
      {
        branch: $branch
        status: $status
      }
    }
  let stale_statuses = $branch_statuses | where status == "deleted from remote"
  let stale_branches = $stale_statuses | get branch
  let worktrees = parse-worktrees
  let stale = $worktrees
    | where { $in.branch in $stale_branches }
    | each {|wt|
      let status = $stale_statuses | where branch == $wt.branch | first | get status
      $wt | insert status $status
    }
  if ($stale | is-empty) {
    print "No stale worktrees found."
    return
  }
  print $"Found ($stale | length) stale worktree\(s\):"
  print ($stale | select worktree branch status)
  let confirm = try {
    input "Delete these worktrees? [y/N] " | str trim | str lowercase
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
