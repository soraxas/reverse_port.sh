#!/bin/sh
#
# By @soraxas
#
# This is a script that helps to open a reverse port (or a range of ports)
# You can let the terminal run in the background and Ctrl-C it when you are done.

usage() {
  script_name=$(basename "$0")

  cat <<EOF
Usage: $script_name <REMOTE_HOST> <PORT>-[PORT_END] [PORT_MAP_TO] [-t|--tunnel TUNNEL_HOST]
        [-r|--reverse] [-b|--bind-address BIND_ADDRESS]
Description:
    This script helps to forward ports (or a range of ports) from a local machine to a remote host (or reverse).
    You can either provide a single port, a range of ports (PORT-PORT_END), or a comma-separated list of ports.
    The script can also map the forwarded ports to different ports on the remote host using the PORT_MAP_TO option.
    Additionally, you can specify a tunnel target host with the -t option and reverse the port forwarding direction
    with the -r option.
Examples:
    1. Forward a single port:
       $script_name user@hostname 9000
    2. Forward a range of ports (9000 to 9020):
       $script_name user@hostname 9000-9020
    3. Forward a range of ports with mapping (9000-9020 mapped to 8000-8020):
       $script_name user@hostname 9000-9020 8000
    4. Forward a comma-separated list of ports (e.g., 9000,9010,9020):
       $script_name user@hostname 9000,9010,9020
    5. Forward a range of ports with reverse mapping (9000-9020, mapped to 8000-8020, reverse):
       $script_name user@hostname 9000-9020 8000 -r
    6. Forward ports with a tunnel target host:
       $script_name user@hostname 9000 -t localhost
    REMOTE_HOST    What you'd normally type to ssh into remote host
                   This is the host that your machine can directly connects to.
                   e.g. user@hostname, ssh-alias
    PORT           Integer of port
                   e.g. 9000
    PORT_END       [Optional] If given, forwards a range of ports (PORT to PORT_END)
                   e.g. 9020
    PORT_MAP_TO    [Optional] If given, maps PORT to this given port.
                   If forwarding a range of ports, the mapped port end is always implied
                   as the corresponding offsetted ports.
                   e.g. 8000
    TUNNEL_HOST    [Optional] This is the target host of the tunnel.
                   This should be a host that REMOTE_HOST can connects to.
                   Defaults to 'localhost' (of the REMOTE_HOST).
    BIND_ADDRESS   [Optional] This is the address to bind the forwarded ports to.
                   If none is given, ssh by default binds to loopback interface.
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
        reverse_mode=true
        ;;
      -t|--tunnel)
        TUNNEL_HOST="$1"
        shift
        ;;
      --debug)
        set -x
        ;;
      -b|--bind-address)
        BIND_ADDRESS="$1:"
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

# Check if PORT contains a hyphen (for range) or commas (for a list)
if [[ "$PORT" == *-* ]]; then
  # It's a port range
  remainder="$PORT"
  PORT="${remainder%%-*}"
  PORT_END="${remainder#*-}"
  # Check if PORT_END is a valid integer
  check_integer "$PORT"
  check_integer "$PORT_END"
  if [ $PORT -gt $PORT_END ]; then
    echo "PORT_END must be greater than or equal to PORT!"
    exit 1
  fi
  if [ -n "$MAP_TO" ]; then
    # If PORT_MAP_TO is given, mapping begins at that port
    check_integer "$MAP_TO"
    map_start=$MAP_TO
    map_end=$((MAP_TO + PORT_END - PORT))
  else
    map_start=$PORT
    map_end=$PORT_END
  fi
  PORT=$(seq -f "%g" "$PORT" "$PORT_END" | paste -sd, -)
  MAP_TO=$(seq -f "%g" "$map_start" "$map_end" | paste -sd, -)
elif [[ "$PORT" == *","* ]]; then
  # It's a comma-separated list of ports
  IFS=',' read -r -a PORTS <<< "$PORT"
  # Validate all port numbers in the list
  for p in "${PORTS[@]}"; do
    check_integer "$p"
  done
  if [ -n "$MAP_TO" ]; then
    # Ensure MAP_TO has the same number of ports as the comma-separated list
    IFS=',' read -r -a MAP_TO_PORTS <<< "$MAP_TO"
    if [ ${#PORTS[@]} -ne ${#MAP_TO_PORTS[@]} ]; then
      echo "The number of ports in PORT_MAP_TO must match the number of ports in PORT!"
      exit 1
    fi
  else
    # If PORT_MAP_TO is not given, map each port to itself
    MAP_TO=$(IFS=,; echo "${PORTS[*]}")
  fi
else
  # Single port
  check_integer "$PORT"
  PORT_END="$PORT"
  MAP_TO="${MAP_TO:-$PORT}"
fi

# Construct multi port command
command=""
i=0
offset=0

# forward local to remote
FLAGS="-L"
if [ "$reverse_mode" ]; then
  # reverse mode (forward remote to local)
  FLAGS="-R"
fi

# Map each port in the comma-separated list
IFS=',' read -r -a PORTS <<< "$PORT"
IFS=',' read -r -a MAP_TO_PORTS <<< "$MAP_TO"
for j in "${!PORTS[@]}"; do
  offset=$(( ${MAP_TO_PORTS[$j]} - ${PORTS[$j]} ))
  target_port=$(( ${PORTS[$j]} + $offset ))
  echo ">> Access port ${PORTS[$j]} via http://localhost:$target_port"
  command="$command $FLAGS $BIND_ADDRESS$target_port:$TUNNEL_HOST:${PORTS[$j]}"
done


# Run SSH command
echo ">> Running command: ssh -N $command $HOST"
ssh -N $command "$HOST"
