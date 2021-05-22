#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage()
{
  printf '%s\n' "Usage: $(basename "$0") <HOST> <PORT>-[PORT_END] [PORT_MAP_TO]"
  printf '\t%s\t\t%s\n' 'HOST'          "What you'd normally type to ssh into remote host"
  printf '\t%s\t\t%s\n' '    '          "e.g. user@hostname, ssh-alias"
  printf '\t%s\t\t%s\n' 'PORT'          "Integer of port"
  printf '\t%s\t\t%s\n' '    '          "e.g. 9000"
  printf '\t%s\t%s\n' 'PORT_END'        "Optional. If given, forwards a range of ports (PORT to PORT_END)"
  printf '\t%s\t%s\n' '        '        "e.g. 9020"
  printf '\t%s\t%s\n' 'PORT_MAP_TO'     "Optional. If given, maps PORT to this given port."
  printf '\t%s\t%s\n' '           '     "If forwarding a range of ports, the mapped port end is always implied"
  printf '\t%s\t%s\n' '           '     "as the corresponding offsetted ports."
  printf '\t%s\t%s\n' '        '        "e.g. 8000"
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
MAP_TO="$3"


# test if given port is a range
if test "${PORT#*-}" != "$PORT"; then
  # in the format of $PORT-$PORT_END
  remainder="$PORT"
  PORT="${remainder%%-*}"; remainder="${remainder#*-}"
  PORT_END="${remainder%%-*}"; remainder="${remainder#*-}"
fi


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

# the offset refers to the differences between PORT and the PORT_TO_MAP_TO
offset=0
if [ -n "$MAP_TO" ]; then
  offset=$(( $MAP_TO - $PORT ))
fi

while [ $i -le $PORT_END ]; do
  command="$command -L $(( $i + $offset )):localhost:$i"
  i=$(($i + 1))
done


# run

echo ">> ssh -N $command $HOST"
ssh -N $command "$HOST"
