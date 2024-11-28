# Port Forwarding Script

This script helps you set up SSH port forwarding for a single port or a range of ports. It can either forward ports from a **remote host** to your **local machine** or perform a **reverse port forward** (local ports to remote). You can also map the ports to different local port numbers if needed. The script allows for flexibility in port forwarding configurations, making it useful for various networking and SSH tunneling tasks.

## Features:
- Forward a single port or a range of ports from a remote host to your local machine (local port forwarding).
- Perform reverse port forwarding (from local machine to remote host).
- Map remote ports to local ports with an optional offset.
- Supports SSH tunneling to a specific target host.

## Prerequisites:
- `ssh` command available and properly configured on your local machine.
- Access to the remote server you want to forward ports from.

## Installation:
1. Download the script and save it to your machine (e.g., `port-forward.sh`).
2. Make it executable by running:
   ```bash
   chmod +x port-forward.sh
   ```
3. You can now use the script to set up port forwarding.

## Usage:

### Basic Syntax:

```bash
./port-forward.sh <REMOTE_HOST> <PORT>-[PORT_END] [PORT_MAP_TO] [OPTIONS]
```

### Arguments:
- `REMOTE_HOST`: The remote host to SSH into (e.g., `user@hostname` or an SSH alias).
- `PORT`: The starting port to forward (e.g., `8080`).
- `PORT_END` (Optional): The ending port for the range of ports to forward (e.g., `8090`). If not specified, the script will forward only the `PORT`.
- `PORT_MAP_TO` (Optional): The local port to map the remote port to (e.g., map remote port `8080` to local port `8000`).

### Options:
- `-t, --tunnel TUNNEL_HOST`: The target host for the tunnel (defaults to `localhost` on the remote host).
- `-r, --reverse`: Reverse SSH: forward local ports to the remote host instead of forwarding remote ports to local.
- `-h, --help`: Show the help message and exit.

### Examples:

1. **Forward a single port from the remote host to the local machine**:
   ```bash
   ./port-forward.sh user@remotehost 8080
   ```
   This will forward port `8080` from the remote host to `localhost:8080`.

2. **Forward a range of ports from the remote host to the local machine**:
   ```bash
   ./port-forward.sh user@remotehost 9000-9020
   ```
   This will forward ports `9000-9020` from the remote host to `localhost:9000-9020`.

3. **Map remote port to a different local port**:
   ```bash
   ./port-forward.sh user@remotehost 9000 8000
   ```
   This will forward port `9000` from the remote host to local port `8000`.

4. **Forward a range of ports from the remote host to a different local port range**:
   ```bash
   ./port-forward.sh user@remotehost 9000-9020 8000
   ```
   This will forward ports `9000-9020` from the remote host to `localhost:8000-8020`.

5. **Reverse SSH: Forward local ports to the remote host**:
   ```bash
   ./port-forward.sh user@remotehost 9000-9020 --reverse
   ```
   This will forward local ports `9000-9020` to the remote host.

6. **Use a custom tunnel target host**:
   ```bash
   ./port-forward.sh user@remotehost 8080 --tunnel mytunnelhost
   ```
   This will forward port `8080` from the remote host to `mytunnelhost:8080` instead of the default `localhost`.

## Notes:
- When using the `--reverse` option, ports will be forwarded **from your local machine to the remote machine**.
- The `PORT_MAP_TO` option can be used to map the remote port(s) to specific local ports. If not used, the script will forward remote ports to the same ports on the local machine.
