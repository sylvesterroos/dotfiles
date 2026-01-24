def get-stale-worktrees [] {
  git fetch --prune

  let worktrees = (git worktree list --porcelain
    | split row "\n\n"
    | each { |wt|
        let lines = ($wt | lines)
        let path = ($lines | where { $in | str starts-with "worktree " } | first | str replace "worktree " "")
        let branch_lines = ($lines | where { $in | str starts-with "branch " })
        let branch = (if ($branch_lines | is-empty) { "" } else { $branch_lines | first | str replace "branch refs/heads/" "" })
        { path: $path, branch: $branch }
      }
    | where { $in.branch != "" }
  )

  let remote_branches = (git branch -r
    | lines
    | str trim
    | where { not ($in | str contains "->") }
    | each { $in | str replace "origin/" "" }
  )

  $worktrees | where { $in.branch not-in $remote_branches }
}

def main [] {
  let stale = (get-stale-worktrees)

  if ($stale | is-empty) {
    print "No stale worktrees found."
    return
  }

  print $"Found ($stale | length) stale worktree\(s\):\n"
  $stale | print
  print ""

  let confirm = (try {
    input "Delete these worktrees? [y/N] " | str trim | str downcase
  } catch { |err|
    # Parse the JSON to get the error structure
    let err_data = ($err.json | from json)
    if ($err_data.code? | default "") == "nu::shell::io::interrupted" {
      print "\nInterrupted."
      return
    }
    # Re-raise other errors
    error make $err
  })

  if $confirm != "y" {
    print "\nAborted."
    return
  }

  print ""

  let results = ($stale | each { |wt|
    print $"Removing worktree: ($wt.path) \(branch: ($wt.branch)\)"
    let result = (do { git worktree remove $wt.path } | complete)
    if $result.exit_code != 0 {
      print $"  ✗ Failed: ($result.stderr | str trim)"
      { path: $wt.path, branch: $wt.branch, error: ($result.stderr | str trim) }
    } else {
      print "  ✓ Removed"
      null
    }
  } | compact)

  if not ($results | is-empty) {
    print $"\n--- Report: ($results | length) worktree\(s\) could not be deleted ---"
    $results | print
  }
}
