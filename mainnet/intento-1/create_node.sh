#!/bin/bash

set -e  # Exit on any error

# Check if MONIKER was provided as argument
if [ -z "$1" ]; then
    echo "Error: MONIKER not provided"
    echo "Usage: $0 <moniker>"
    echo "Example: $0 my-validator-node"
    exit 1
fi

# set variables
CHAINID="intento-1"
MONIKER="$1"
DENOM="uinto"
ATOM="ibc/C4CFF46FD6DE35CA4CF4CE031E643C8FDC9BA4B99AE598E9B0ED98FE3A2319F9"
VERSION="v1.0.0"
PEERS="06bf7c52e0584d91a9d7c9f71141f246c3347d5a@144.126.208.31"
SEED="3a1d847563a1ea3b3e6195c3e4f9e90d9b4f7b56@tenderseed.ccvalidators.com:29111" 
GENESIS_URL="https://raw.githubusercontent.com/trstlabs/networks/main/mainnet/intento-1/genesis.json"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <moniker>"
    exit 1
fi
MONIKER="$1"
if [[ "$MONIKER" == "YOUR_MONIKER" ]]; then
    echo "Please set your MONIKER before running this script"
    exit 1
fi

# ----------------------
# Install binaries
# ----------------------
BIN_DIR="/usr/local/bin"
sudo mkdir -p "$BIN_DIR"

# cosmovisor
if ! command -v cosmovisor >/dev/null; then
    echo "Installing cosmovisor..."
    curl -L https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.7.1/cosmovisor-v1.7.1-linux-amd64.tar.gz \
        | sudo tar -xz -C "$BIN_DIR" cosmovisor
    sudo chmod +x "$BIN_DIR/cosmovisor"
fi

# intentod
echo "Downloading intentod $VERSION..."
curl -L "https://github.com/trstlabs/intento/releases/download/$VERSION/intentod_linux_amd64_$VERSION" \
    -o /tmp/intentod
sudo mv /tmp/intentod "$BIN_DIR/intentod"
sudo chmod +x "$BIN_DIR/intentod"

# wasmvm
wget -O /usr/local/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v2.2.4/libwasmvm.x86_64.so
sudo ldconfig /usr/local/lib

# Backup old data
if [[ -d "$HOME_DIR/.intento" ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME_DIR/.intento" "$HOME_DIR/.intento.bak_$TIMESTAMP"
fi

# Setup cosmovisor directory
COSMOVISOR_GENESIS="$HOME_DIR/.intento/cosmovisor/genesis/bin"
mkdir -p "$COSMOVISOR_GENESIS"
cp "$BIN_DIR/intentod" "$COSMOVISOR_GENESIS/intentod"

# ----------------------
# Init node
# ----------------------
intentod init "$MONIKER" --chain-id "$CHAINID"

# ----------------------
# Download genesis
# ----------------------
curl -L "$GENESIS_URL" -o "$HOME_DIR/.intento/config/genesis.json"

# ----------------------
# Update configs
# ----------------------
CONFIG_TOML="$HOME_DIR/.intento/config/config.toml"
APP_TOML="$HOME_DIR/.intento/config/app.toml"
CLIENT_TOML="$HOME_DIR/.intento/config/client.toml"

sed -i -E "s|cors_allowed_origins = \[\]|cors_allowed_origins = [\"*\"]|g" "$CONFIG_TOML"
sed -i -E "s|127.0.0.1|0.0.0.0|g" "$CONFIG_TOML"
sed -i -E "s|seeds = \".*\"|seeds = \"$SEED\"|g" "$CONFIG_TOML"
sed -i -E "s|persistent_peers = \".*\"|persistent_peers = \"$PEERS\"|g" "$CONFIG_TOML"

sed -i -E "s|minimum-gas-prices = \".*\"|minimum-gas-prices = \"0.001$DENOM,0.001$ATOM\"|g" "$APP_TOML"
sed -i -E '/\[api\]/,/^enable = .*$/ s/^enable = .*$/enable = true/' "$APP_TOML"
sed -i -E 's|swagger = .*|swagger = true|g' "$APP_TOML"
sed -i -E 's|unsafe-cors = .*|unsafe-cors = true|g' "$APP_TOML"
sed -i -E 's|localhost|0.0.0.0|g' "$APP_TOML"

sed -i -E "s|chain-id = \".*\"|chain-id = \"$CHAINID\"|g" "$CLIENT_TOML"
sed -i -E "s|keyring-backend = \"os\"|keyring-backend = \"test\"|g" "$CLIENT_TOML"

# ----------------------
# systemd service
# ----------------------
SERVICE_FILE="/etc/systemd/system/intentod.service"
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Intento Node
After=network-online.target

[Service]
User=$USER
ExecStart=$BIN_DIR/cosmovisor run start
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
Environment="DAEMON_HOME=/root/.intento"
Environment="DAEMON_NAME=intentod"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="LD_LIBRARY_PATH=/usr/local/lib"

[Install]
WantedBy=multi-user.target
EOF

# ----------------------
# Enable + start service
# ----------------------
sudo systemctl daemon-reload
sudo systemctl enable intentod
sudo systemctl restart intentod

echo "✅ Node setup complete. Check logs with:"
echo "    sudo journalctl -fu intentod -o cat"
