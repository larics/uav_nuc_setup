#!/bin/bash

alias cd..='cd ..'

alias re-source='source ~/.bashrc'

# Short commands for common tools.
# With this alias, when returning from Ranger, current directory will be the last one you were positioned in while in Ranger.
alias ra='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'
# If you don-t want this behaviour, uncomment the alias bellow, and comment out the one above.
# alias ra='ranger'