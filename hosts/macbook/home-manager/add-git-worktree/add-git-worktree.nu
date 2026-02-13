def main [substring?: string] {
  git fetch --prune origin

  let branches = (git branch -a
    | lines
    | str trim
    | where { not ($in | str contains "->") }
    | each { $in | str replace -r '^\* ' '' | str replace "remotes/origin/" "" }
    | uniq
  )

  let query = ($substring | default "")

  let branch = ($branches | str join "\n" | fzf --height=~50% --border --prompt="Select branch: " --query $query | str trim)

  if ($branch | is-empty) {
    return
  }

  let worktrees = (git worktree list --porcelain
    | split row "\n\n"
    | each { |wt|
        let lines = ($wt | lines)
        let path = ($lines | where { $in | str starts-with "worktree " } | first | str replace "worktree " "")
        let branch_lines = ($lines | where { $in | str starts-with "branch " })
        let branch = (if ($branch_lines | is-empty) { "" } else { $branch_lines | first | str replace "branch refs/heads/" "" })
        { path: $path, branch: $branch }
      }
  )

  let develop_matches = ($worktrees | where { $in.branch == "develop" })

  if ($develop_matches | is-empty) {
    print "Could not find 'develop' worktree."
    return
  }

  let develop_worktree = ($develop_matches | first)
  let parent_dir = ($develop_worktree.path | path dirname)
  let worktree_path = ($parent_dir | path join $branch)

  print $"Creating worktree at: ($worktree_path)"
  print $"Tracking branch: origin/($branch)"

  cd $develop_worktree.path
  git worktree add $worktree_path $branch
}
