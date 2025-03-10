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
CHAINID="intento-ics-test-1"
MONIKER="$1"
DENOM="uinto"

ATOM="ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2"

VERSION="v0.9.1"

PEERS=""
SEED=""

# Add after variables section
if [ "$MONIKER" = "YOUR_MONIKER" ]; then
    echo "Please set your MONIKER before running this script"
    exit 1
fi

# create the /etc/systemd/system/intentod.service file if it doesn't exist with the following content
if [ ! -f /etc/systemd/system/intentod.service ]; then
    sudo tee /etc/systemd/system/intentod.service > /dev/null <<EOF
[Unit]
Description=Intento Node
After=network-online.target

[Service]
User=ubuntu
ExecStart=/home/ubuntu/go/bin/cosmovisor run start
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
Environment="DAEMON_NAME=intentod"
Environment="DAEMON_HOME=/home/ubuntu./intento"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF
fi

# enable the intentod service
sudo systemctl daemon-reload
sudo systemctl enable intentod.service

# stop the node
sudo systemctl stop intentod.service

# backup the old data if any
if [ -d "$HOME./intento.bak" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME./intento.bak" "$HOME./intento.bak_$TIMESTAMP"
fi
# move the old data to the backup folder if there is one
if [ -d "$HOME./intento" ]; then
    mv "$HOME./intento" "$HOME./intento.bak"
fi

# create the $HOME/go/bin folder if it doesn't exist
mkdir -p $HOME/go/bin

# download the new binary from releases
echo "Downloading Intento binary..."
curl -L https://github.com/trstlabs/intento/releases/download/$VERSION/intentod_linux_amd64_$VERSION -o $HOME/go/bin/intentod || {
    echo "Failed to download binary"
    exit 1
}
chmod +x $HOME/go/bin/intentod

# check if $HOME/go/bin is in the PATH otherwise add it to the .bashrc file
if ! echo $PATH | grep -q "$HOME/go/bin"; then
    echo "export PATH=\"$HOME/go/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$HOME/go/bin:$PATH"
    source ~/.bashrc
fi

# Verify binary exists after download
if ! command -v intentod &> /dev/null; then
    echo "intentod binary not found after installation"
    exit 1
fi

# if cosmovisor is not installed, install it
if ! command -v cosmovisor &> /dev/null; then
    echo "cosmovisor not found, installing it..."
    curl -L https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.7.0/cosmovisor-v1.7.0-linux-amd64.tar.gz | tar -xz -C $HOME/go/bin cosmovisor && chmod +x $HOME/go/bin/cosmovisor
fi

# init the new node
intentod init $MONIKER --chain-id $CHAINID

# update config files and fetch genesis
config_toml="$HOME./intento/config/config.toml"
client_toml="$HOME./intento/config/client.toml"
app_toml="$HOME./intento/config/app.toml"
genesis_json="$HOME./intento/config/genesis.json"

sed -i -E "s|cors_allowed_origins = \[\]|cors_allowed_origins = [\"\*\"]|g" $config_toml

sed -i -E "s|127.0.0.1|0.0.0.0|g" $config_toml
sed -i -E "s|seeds = \".*\"|seeds = \"$SEED\"|g" $config_toml
sed -i -E "s|persistent_peers = \".*\"|persistent_peers = \"$PEERS\"|g" $config_toml

sed -i -E "s|minimum-gas-prices = \".*\"|minimum-gas-prices = \"0.001$DENOM,0.001$ATOM\"|g" $app_toml
sed -i -E '/\[api\]/,/^enable = .*$/ s/^enable = .*$/enable = true/' $app_toml
sed -i -E 's|swagger = .*|swagger = true|g' $app_toml
sed -i -E "s|localhost|0.0.0.0|g" $app_toml
sed -i -E 's|unsafe-cors = .*|unsafe-cors = true|g' $app_toml


sed -i -E "s|chain-id = \".*\"|chain-id = \"$CHAINID\"|g" $client_toml
sed -i -E "s|keyring-backend = \"os\"|keyring-backend = \"test\"|g" $client_toml

curl https://raw.githubusercontent.com/trstlabs/networks/refs/heads/main/testnet/$CHAINID/genesis.json -o $genesis_json

# setup cosmovisor
mkdir -p $HOME./intento/cosmovisor/upgrades/$VERSION/bin && cp -a $HOME/go/bin/intentod $HOME./intento/cosmovisor/upgrades/$VERSION/bin/intentod && rm -rf $HOME./intento/cosmovisor/current && ln -sf $HOME./intento/cosmovisor/upgrades/$VERSION $HOME./intento/cosmovisor/current

# start the node
sudo systemctl start intentod.service

# check if the node is running
sudo systemctl status intentod.service

# check logs
sudo journalctl -fu intentod.service -o cat