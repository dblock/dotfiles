source ~/.git-prompt.sh
source ~/.git-completion.sh
source ~/.bash_aliases

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

[[ -s "$HOME/.nvm/nvm.sh" ]] && source "$HOME/.nvm/nvm.sh"

PATH=$PATH:$HOME/.bin
PS1="\[\033[01;34m\]testbox \[\033[00m\]\w\$(__git_ps1)\$ "

export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export GPG_TTY=$(tty)

ssh-add -K

cd ~/source/opensearch-project

screen-me

