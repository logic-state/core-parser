#/bin/sh

# Install tools for live interactive
install-pkg graphviz && dot -c
wget https://github.com/watchexec/watchexec/releases/download/1.14.0/watchexec-1.14.0-x86_64-unknown-linux-gnu.tar.xz \
-O - | tar -xJ -C .. --strip 1 --no-anchored 'watchexec'
wget https://github.com/sharkdp/bat/releases/download/v0.15.4/bat-v0.15.4-x86_64-unknown-linux-gnu.tar.gz \
-O - | tar -xz -C .. --strip 1 --no-anchored 'bat'

# Compile 2 version of logicstate
nimble -d:tsInterface -o:'../lost-code' -y compile src/main.nim
nimble -d:dot -o:'../lost-diagram' -y compile src/main.nim

# Live reload
../watchexec -c -w examples -e logic 'cat examples/detective.logic | ../lost-diagram | dot -Tsvg > examples/detective.svg' &
../watchexec -c -w examples -e logic 'cat examples/detective.logic | ../lost-code | ../bat -n -l ts'
