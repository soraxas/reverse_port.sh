#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage()
{
  printf '%s\n' "Usage: $(basename "$0") <HOST> <PORT> [PORT_END]"
  printf '\t%s\t\t%s\n' 'HOST'      "What you'd normally type to ssh into remote host"
  printf '\t%s\t\t%s\n' '    '      "e.g. user@hostname, ssh-alias"
  printf '\t%s\t\t%s\n' 'PORT'      "Integer of port"
  printf '\t%s\t\t%s\n' '    '      "e.g. 9000"
  printf '\t%s\t%s\n' 'PORT_END'    "Optional. If given, forwards a range of ports (PORT to PORT_END)"
  printf '\t%s\t%s\n' '        '    "e.g. 9020"
}

check_integer()
{
  case "$1" in
    ''|*[!0-9]*) echo "PORT must be an integer!"; usage; exit 1 ;;
    *) ;;
  esac
}

if [ $# -ne 2 -a $# -ne 3 ]; then
  echo "Must provide two or three arguments!\n"
  usage
  exit 1
fi

HOST="$1"
PORT="$2"
PORT_END="$3"

# check ports are integer
check_integer "$PORT"
if [ ! -z "$PORT_END" ]; then
  echo "> Forwarding ports $PORT to $PORT_END from $HOST..."
  check_integer "$PORT_END"
  if [ $PORT -gt $PORT_END ]; then
    echo "PORT_END must be less than or equal to PORT!"
    exit 1
  fi
else
  echo "> Forwarding port $PORT from $HOST..."
  PORT_END="$PORT"
fi

# construct multi port command
command=""
i=$PORT
while [ $i -le $PORT_END ]; do
  command="$command -L $i:localhost:$i"
  i=$(($i + 1))
done

# run

ssh -N $command "$HOST"
