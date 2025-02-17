# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d";
	source "$(brew --prefix)/etc/profile.d/bash_completion.sh";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;




# export CLICOLOR=1
# # sets up thecolor scheme for list export
# export LSCOLORS=gxfxcxdxbxegedabagacad
# # sets up theprompt color (currently a green similar to linux terminal)
# export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '
# # enables colorfor iTerm
# export TERM=xterm-256color

# File search functions
#function f() { find . -iname "*$1*" ${@:2} }
#function r() { grep "$1" ${@:2} -R . }
# Create a folder and move into it in one command
#function mkcd() { mkdir -p "$@" && cd "$_"; }

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/xujiazhe/.sdkman"
[[ -s "/Users/xujiazhe/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/xujiazhe/.sdkman/bin/sdkman-init.sh"
