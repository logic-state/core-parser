#/bin/sh
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Install tool for interactive prompt
if ! [ -d ../inquirer ]; then
  mkdir ../inquirer && wget https://github.com/kahkhang/Inquirer.sh/archive/master.tar.gz \
  -qO - | tar -xz -C ../inquirer --strip 1
  pushd ../inquirer ; ./build.py ; popd
fi
[ -x "$(command -v bc)" ] || install-pkg bc && clear
source ../inquirer/dist/list_input.sh


# Interactive prompts
codes=( 'Javascript' 'Typescript' 'Typescript Interface' )
list_input "Which code to generate?" codes sel_code

if [ "$sel_code" != 'Typescript Interface' ]; then
  impls=( 'Type State' 'State Pattern' )
  list_input "And the state machine going to be implemented as ..." impls sel_impl
fi

case $sel_code in
  'Typescript Interface') fmt=tsInterface ; hl=ts ; impl=typestate ;;
  'Typescript') fmt=tsCode ; hl=ts ;;
  'Javascript') fmt=jsCode ; hl=js ;;
esac

case $sel_impl in
  'Type State') impl=typestate ;;
  'State Pattern') impl=statepattern ;;
esac

echo '===================================='
echo 'running examples/detective.logic'
echo -e "        $YELLOW^^^^^^^^^^^^^^^^^^^^^^^^ open that, pelase 🥺$NC"
echo 'PLEASE WAIT...'
echo 'we are building the compiler 😂'
echo '===================================='


# Install tools for live interactive
[ -x "$(command -v dot)" ] || install-pkg graphviz && dot -c

[ -f ../watchexec ] || wget \
https://github.com/watchexec/watchexec/releases/download/1.14.0/watchexec-1.14.0-x86_64-unknown-linux-gnu.tar.xz \
-qO - | tar -xJ -C .. --strip 1 --no-anchored 'watchexec'

[ -f ../bat ] || wget \
https://github.com/sharkdp/bat/releases/download/v0.15.4/bat-v0.15.4-x86_64-unknown-linux-gnu.tar.gz \
-qO - | tar -xz -C .. --strip 1 --no-anchored 'bat'


# Compile 2 version of logicstate
nimble -d:$fmt -d:$impl -o:'../lost-code' -y compile src/main.nim
[ -f ../lost-diagram ] || nimble -d:dot -o:'../lost-diagram' -y compile src/main.nim


# Live reload
../watchexec -c -w examples -e logic 'cat examples/detective.logic | ../lost-diagram | dot -Tsvg > examples/detective.svg' &
../watchexec -c -w examples -e logic "cat examples/detective.logic | ../lost-code | ../bat -p -l $hl"
