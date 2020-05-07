#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage()
{
  echo "Usage: $0 HOST PORT [PORT_END]"
  echo " |HOST|: What you'd normally type to ssh to remote."
  echo "         e.g. user@hostname:sshport"
  echo " |PORT|: Integer of port."
  echo "         e.g. 9000"
  echo " |PORT_END|: Optional. If given, PORT-PORT_END range will be forwarded."
  echo "         e.g. 9020"
}

check_integer()
{
  case "$1" in
    ''|*[!0-9]*) echo "PORT must be an integer!"; usage; exit 1 ;;
    *) ;;
  esac
}

if [ $# -ne 2 -a $# -ne 3 ]; then
  echo "Must provide two or three arguments!"
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
