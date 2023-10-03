#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage()
{
  printf '%s\n' "Usage: $(basename "$0") <REMOTE_HOST> <PORT>-[PORT_END] [PORT_MAP_TO]"
  printf '%s\n' "                        [-t|--tunnel TUNNEL_HOST]"
  printf '\t%s\t%s\n' 'REMOTE_HOST'   "What you'd normally type to ssh into remote host"
  printf '\t%s\t\t%s\n' '    '          "This is the host that your machine can directly connects to."
  printf '\t%s\t\t%s\n' '    '          "e.g. user@hostname, ssh-alias"
  printf '\t%s\t\t%s\n' 'PORT'          "Integer of port"
  printf '\t%s\t\t%s\n' '    '          "e.g. 9000"
  printf '\t%s\t%s\n' 'PORT_END'        "[Optional] If given, forwards a range of ports (PORT to PORT_END)"
  printf '\t%s\t%s\n' '        '        "e.g. 9020"
  printf '\t%s\t%s\n' 'PORT_MAP_TO'     "[Optional] If given, maps PORT to this given port."
  printf '\t%s\t%s\n' '           '     "If forwarding a range of ports, the mapped port end is always implied"
  printf '\t%s\t%s\n' '           '     "as the corresponding offsetted ports."
  printf '\t%s\t%s\n' '        '        "e.g. 8000"
  printf '\t%s\t%s\n' 'TUNNEL_HOST'     "[Optional] This is the target host of the tunnel."
  printf '\t%s\t%s\n' '           '     "This should be a host that REMOTE_HOST can connects to."
  printf '\t%s\t%s\n' '           '     "Defaults to 'localhost' (of the REMOTE_HOST)."
}

check_integer()
{
  case "$1" in
    ''|*[!0-9]*) echo "PORT must be an integer!"; usage; exit 1 ;;
    *) ;;
  esac
}

TUNNEL_HOST=localhost

# shellcheck disable=SC2116,SC2028
EOL=$(echo '\00\07\01\00')
if [ "$#" != 0 ]; then
  set -- "$@" "$EOL"
  while [ "$1" != "$EOL" ]; do
    opt="$1"; shift
    case "$opt" in
      -h|--help)
        usage
        exit 0
        ;;
      -t|--tunnel)
        TUNNEL_HOST="$1"
        if [ -n "TUNNEL_HOST" ]; then
          usage
          exit 1
        fi
        shift
        ;;
      --*=*)  # convert '--name=arg' to '--name' 'arg'
        set -- "${opt%%=*}" "${opt#*=}" "$@";;
      -[!-]?*)  # convert '-abc' to '-a' '-b' '-c'
        # shellcheck disable=SC2046  # we want word splitting
        set -- $(echo "${opt#-}" | sed 's/\(.\)/ -\1/g') "$@";;
      --)  # process remaining arguments as positional
        while [ "$1" != "$EOL" ]; do set -- "$@" "$1"; shift; done;;
      -*)
        echo "Error: Unsupported flag '$opt'" >&2
        exit 1
        ;;
      *)
        # set back any unused args
        set -- "$@" "$opt"
    esac
  done
  shift # remove the EOL token
fi


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
  target_port=$(( $i + $offset ))
  echo ">> Access port $i via http://localhost:$target_port"
  command="$command -L $target_port:$TUNNEL_HOST:$i"
  i=$(($i + 1))
done


# run

echo ">> Running command: ssh -N $command $HOST"
ssh -N $command "$HOST"
