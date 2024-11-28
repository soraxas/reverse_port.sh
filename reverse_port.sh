#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage()
{
  cat <<EOF
Usage: $(basename "$0") <REMOTE_HOST> <PORT>-[PORT_END] [PORT_MAP_TO] [OPTIONS]

Description:
  This script forwards a range of ports (or a single port) from a remote host to the local machine (or vice versa for reverse SSH).
  It allows you to specify a range of ports and map them to local ports, with an optional tunnel to another host.

Arguments:
  REMOTE_HOST      The remote host to SSH into (e.g., user@hostname or ssh-alias).
  PORT             The starting port (e.g., 9000).
  PORT_END         [Optional] The ending port for the range. If not specified, a single port is used.
  PORT_MAP_TO      [Optional] The local port to map to (defaults to the same port as the remote).

Options:
  -t, --tunnel TUNNEL_HOST  The target host for the tunnel (defaults to 'localhost' on REMOTE_HOST).
  -r, --reverse             Reverse SSH: Forward local ports to the remote host instead of remote to local.
  -h, --help                Show this help message and exit.

Examples:
  $(basename "$0") user@remotehost 8080        Forward port 8080 from the remote host to localhost:8080.
  $(basename "$0") user@remotehost 9000-9020    Forward ports 9000-9020 from the remote host to localhost:9000-9020.
  $(basename "$0") user@remotehost 9000 8000    Forward port 9000 from the remote host to local port 8000.
  $(basename "$0") user@remotehost 9000-9020 8000  Forward ports 9000-9020 from the remote host to local ports 8000-8020.
  $(basename "$0") user@remotehost 9000-9020 --reverse    Reverse forward ports 9000-9020 from local to remote.

EOF
}

check_integer()
{
  case "$1" in
    ''|*[!0-9]*) echo "PORT must be an integer!"; usage; exit 1 ;;
    *) ;;
  esac
}

TUNNEL_HOST=localhost

DIRECTION="-L"

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
      -r|--reverse)
        DIRECTION="-R"
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
  printf '%s\n\n' "> Must provide two or three arguments!"
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
  command="$command $DIRECTION $target_port:$TUNNEL_HOST:$i"
  i=$(($i + 1))
done


# run

echo ">> Running command: ssh -N $command $HOST"
ssh -N $command "$HOST"
