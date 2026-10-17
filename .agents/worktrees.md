# Worktrees

`tool/worktrees.sh list` shows every worktree with its owner tool and whether it holds uncommitted work;
`tool/worktrees.sh prune` removes the clean ones and keeps dirty ones unless `--force` is passed. The owner is
inferred from the worktree path, and anything unrecognized reports as `other`.
