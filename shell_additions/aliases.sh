#!/bin/bash

alias cd..='cd ..'
alias cbt='catkin build --this'
alias re-source='source ~/.bashrc'
alias gitg='git log --graph --pretty=oneline --abbrev-commit --all'

# Short commands for common tools.
# With this alias, when returning from Ranger, current directory will be the last one you were positioned in while in Ranger.
alias ra='. ranger'
# If you don-t want this behaviour, uncomment the alias bellow, and comment out the one above.
# alias ra='ranger'
