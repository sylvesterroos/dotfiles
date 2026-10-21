#!/usr/bin/env nu
# Copies Home Assistant's backups to Proton Drive and keeps the newest of them
# there.
#
# Home Assistant writes each archive in place, so an archive modified within
# the last hour may still be growing; the next run uploads it. Drive keeps its
# own history: archives Home Assistant has pruned stay in Drive until they fall
# out of the newest KEEP. KEEP exceeds Home Assistant's own retention, so every
# archive still on disk is among those Drive keeps.
#
# Paths and values arrive through the environment.
def --wrapped drive [...args: string] { ^$env.PROTON_DRIVE ...$args }
def children [folder: string, type: string] {
    drive filesystem list --json --type $type $folder | from json
}
# Creates each missing folder of the remote path below the Drive root.
let root = "/my-files"
let segments = ($env.REMOTE | path relative-to $root | path split)
for segment in ($segments | enumerate) {
    let parent = ([
        $root
        ...($segments | first $segment.index)
    ] | path join)
    if $segment.item not-in (children $parent folder | get name.value) {
        drive filesystem create-folder $parent $segment.item
    }
}
let settled = (ls $env.BACKUPS | where type == file and ($it.name | str ends-with ".tar") and modified < ((date now) - 1hr) | get name)
if ($settled | is-not-empty) {
    drive filesystem upload --file-conflict-strategy skip --skip-thumbnails ...$settled $env.REMOTE
}
# Age is the archive's own mtime, which upload records as the claimed
# modification time; the node's creationTime is when Drive received it.
let expired = (
    children $env.REMOTE file | sort-by activeRevision.claimedModificationTime --reverse | skip ($env.KEEP | into int) | each {|node| $env.REMOTE | path join $node.name.value }
)
if ($expired | is-not-empty) {
    let failed = (drive filesystem trash --json ...$expired | from json | where not ok | get uid)
    if ($failed | is-not-empty) {
        error make {
            msg: $"trash failed for nodes: ($failed | str join ', ')"
        }
    }
}
