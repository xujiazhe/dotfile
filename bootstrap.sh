#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~;
	source ~/.bash_profile;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;

#
# 文件合并后删除
# ~ 文件 指 进来  包括bin   除了 .gitignore .vimrc




for file in ~/.{aliases,bash_profile,bash_prompt,bashrc,curlrc,editorconfig,\
exports,functions,gdbinit,gitattributes,gitconfig,gvimrc,hgignore,hushlogin,\
inputrc,screenrc,wgetrc,tmux.conf,macos}; do
  ln $file ~
done;

ln brew.sh ~
ln vimrc ~/vimrc
ln gitignore ~/.gitignore
ln -sfn bin ~

#  path,bash_prompt,exports,aliases,functions,extra}; do
#	[ -r "$file" ] && [ -f "$file" ] && source "$file";
