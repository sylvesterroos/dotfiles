def main [substring: string] {
  git fetch --prune origin

  let matching_branches = (git branch -a
    | lines
    | str trim
    | where { not ($in | str contains "->") }
    | each { $in | str replace -r '^\* ' '' | str replace "remotes/origin/" "" }
    | uniq
    | where { $in | str contains $substring }
  )

  if ($matching_branches | is-empty) {
    print $"No branches found matching '($substring)'"
    return
  }

  print "Matching branches:"
  $matching_branches | enumerate | each { |it| print $"  ($it.index): ($it.item)" }
  print ""

  let selection = (try {
    input "Select branch number: " | str trim | into int
  } catch {
    print "\nInvalid selection."
    return
  })

  if $selection < 0 or $selection >= ($matching_branches | length) {
    print "Selection out of range."
    return
  }

  let branch = ($matching_branches | get $selection)

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
