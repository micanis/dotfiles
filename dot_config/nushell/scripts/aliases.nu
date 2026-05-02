# Aliases

# Navigation (zoxide provides `z` / `zi` via autoload)
alias ll  = eza -la --git --icons
alias la  = eza -a  --icons
alias lt  = eza --tree --level=2 --icons
alias ..  = cd ..
alias ... = cd ../..

# Editor
alias e = hx
alias v = hx

# Git
alias g    = git
alias gs   = git status
alias ga   = git add
alias gc   = git commit
alias gp   = git push
alias gl   = git pull
alias gd   = git diff
alias glog = git log --oneline --graph --decorate --all
alias lg   = lazygit

# Zellij
alias zj = zellij

# Modern replacements
alias cat = bat
alias du  = dust
alias ps  = procs

# Misc
alias c = clear
