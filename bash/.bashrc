source ~/.git-prompt.sh
source ~/.git-completion.sh

source ~/.bash_aliases

unset HISTFILE

[[ -s "$HOME/.local/bin" ]] && PATH=$PATH:$HOME/.local/bin # Added by pipx
[[ -s "$HOME/.rvm/bin" ]] && PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
[[ -s "$HOME/.bin" ]] && PATH=$PATH:$HOME/.bin

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
[[ -s "$HOME/.nvm/nvm.sh" ]] && source "$HOME/.nvm/nvm.sh"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm" # Load GVM into a shell session *as a function*
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -f '/Applications/google-cloud-sdk/path.bash.inc' ]] && source '/Applications/google-cloud-sdk/path.bash.inc'
[[ -f '/Applications/google-cloud-sdk/completion.bash.inc' ]] && source '/Applications/google-cloud-sdk/completion.bash.inc'
[[ -f '/opt/homebrew/bin/brew' ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

PS1="\[\033[01;172m\]\w\[\033[00m\]\$(__git_ps1)\$ "

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export GPG_TTY=$(tty)
export BASH_SILENCE_DEPRECATION_WARNING=1


# ssh-add
