#!/usr/bin/env bash

# 文件合并后删除
# ~ 文件 指 进来  包括bin   除了 .gitignore .vimrc

cd "$(dirname "${BASH_SOURCE}")"

forcelink() {
  for file in .{aliases,bash_profile,bash_prompt,bashrc,curlrc,editorconfig,exports,functions,gdbinit,gitattributes,gitconfig,gvimrc,hgignore,hushlogin,inputrc,screenrc,wgetrc,tmux.conf,macos,extra,path}; do
    [ -r ~/"$file" ] && [ -f ~/"$file" ] && rm ~/$file
    ln $file ~
    #  ll -i $file ~/$file
  done
  unset file

  file=vimrc
  [ -r ~/"$file" ] && [ -f ~/"$file" ] && rm ~/$file && ln $file ~
  file=brew.sh
  [ -r ~/"$file" ] && [ -f ~/"$file" ] && rm ~/$file && ln $file ~

  file=.gitignore
  [ -r ~/"$file" ] && [ -f ~/"$file" ] && rm ~/$file && ln gitignore ~/"$file"

  unset file

  ln -sfn $PWD/bin ~/bin
}

forcelink

# TODO 学习 gitconfig的配置
# TODO 安装brew
# TODO 安装 .macos
