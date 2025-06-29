This guide is loosely based on the [Elys Network network repository](https://github.com/elys-network/networks) but has been adapted for Intento. Follow the steps below to set up your node.

---

# Joining the Intento Testnet (ICS)

Welcome to the Intento testnet! This guide will walk you through setting up a full node and joining the testnet. The testnet is designed to test Interchain Security functionality and ensure overall network stability.

We implement an allowlist for the validators. If you are not on the allowlist, you will not be able to join the network as a validator. If you are an active Cosmos Hub validator on mainnet, please reach out to us on Discord for getting on the allow list .

## Quick Reference

- **Consumer ID**: 4 
- **Binary**: `intentod`
- **Chain ID**: `intento-ics-test-1`
- **Critera**: `Active Cosmos Hub validator on mainnet`

## Hardware Requirements

| Component   | Minimum Specification |
| ----------- | --------------------- |
| **CPU**     | 4 cores               |
| **RAM**     | 16 GB                 |
| **Storage** | 200 GB SSD            |
| **Network** | 100 Mbps+             |

## Software Requirements

- **Operating System**: Linux 20.04+
- **Go**: v1.22.7 or later

## Node Setup Instructions

> **⚠️ Important Note for Validators**:
>
> - Review the script before running it.
> - Replace the generated key at `$HOME/.intento/config/priv_validator_key.json` with your actual testnet key.
> - Start the node only after replacing your key to prevent double signing.

### Node Setup

1. **Clone the Repository and Build the Binary**

```bash
git clone https://github.com/trstlabs/intento.git
cd intento
git checkout v0.9.4-r4
make install
```

Make install installs intentod at ./cmd/intentod. You can also run `make build` to build the binary.

Initialize your node:

```bash
intentod init [your-moniker] --chain-id intento-ics-test-1
```

1. **Configure Your Node**

   - **Download the Genesis File**:
     ```bash
     curl -o $HOME/.intento/config/genesis.json https://raw.githubusercontent.com/trstlabs/networks/main/testnet/intento-ics-test-1/genesis.json
     ```
   - **Replace Validator Key (For Validators Only)**:
     ```bash
     mv /path/to/your/priv_validator_key.json $HOME/.intento/config/priv_validator_key.json
     ```
   - **Edit Node Settings**:
     Update `$HOME/.intento/config/config.toml` with persistent peers and seeds and other variables. These are to be shared amongst validators in Discord. We will be adding a list of peers and seeds soon.

From ./create_node.sh example script:

```bash
config_toml="$HOME/.intento/config/config.toml"
client_toml="$HOME/.intento/config/client.toml"
app_toml="$HOME/.intento/config/app.toml"
genesis_json="$HOME/.intento/config/genesis.json"

ATOM="ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2"
CHAINID="intento-ics-test-1"

sed -i -E "s|cors_allowed_origins = \[\]|cors_allowed_origins = [\"*\"]|g" $config_toml

sed -i -E "s|127.0.0.1|0.0.0.0|g" $config_toml
sed -i -E "s|seeds = \".*\"|seeds = \"$SEED\"|g" $config_toml
sed -i -E "s|persistent_peers = \".*\"|persistent_peers = \"$PEERS\"|g" $config_toml

sed -i -E "s|minimum-gas-prices = \".*\"|minimum-gas-prices = \"0.001uinto,0.001$ATOM\"|g" $app_toml
sed -i -E '/\[api\]/,/^enable = .*$/ s/^enable = .*$/enable = true/' $app_toml
sed -i -E 's|swagger = .*|swagger = true|g' $app_toml
sed -i -E "s|localhost|0.0.0.0|g" $app_toml
sed -i -E 's|unsafe-cors = .*|unsafe-cors = true|g' $app_toml

sed -i -E "s|chain-id = \".*\"|chain-id = \"$CHAINID\"|g" $client_toml
sed -i -E "s|keyring-backend = \"os\"|keyring-backend = \"test\"|g" $client_toml
```

1. **Fake Cosmos Hub Registration** (Required for ICS Testing)

Before setting up your node, validators must opt-in\* to the Intento testnet via a fake Cosmos Hub.

NOTE: It is not needed to run a provider chain node for the testnet!

Follow these steps:

- **Request ATOM from Discord faucet**


**$request cosmos1... cosmos-test**

- This will send you 2000000 fake uatom to your wallet. Use it wisely. Faucet is limited to 1 request per day per address.

- **Clone the Gaia Repository and Build the Binary**

  ```bash
  git clone https://github.com/cosmos/gaia.git
  cd gaia
  git checkout v22.1.0
  make install # or make build, in case of issues you may try also try LDFLAGS="" make install
  ```

  For more information, please check [installing gaia](https://hub.cosmos.network/main/getting-started/installation) or `wasmvm` [documentation](https://github.com/CosmWasm/wasmvm).

- **Initialize the directory**:
  ```bash
   gaiad init --home $PROVIDER_HOME --chain-id GAIA <node-moniker>
  ```

- **Retrieve Your Validator Pubkey**:
  ```bash
  gaiad tendermint show-validator
  ```
- **Create a `validator.json` File**:
  ```bash
  cat <<EOF > /tmp/validator.json
  {
      "pubkey": "[PUBKEY]",
      "amount": "1200000uatom",
      "moniker": "[MONIKER]",
      "identity": "validator",
      "website": "https://intentotestnet.example.com",
      "security": "team@intentotestnet.example.com",
      "details": "Optional validator details",
      "commission-rate": "0.1",
      "commission-max-rate": "0.2",
      "commission-max-change-rate": "0.01",
      "min-self-delegation": "1"
  }
  EOF
  ```
- **Register as a Validator**:
  ```bash
  gaiad tx staking create-validator \
      /tmp/validator.json \
      --from [YOUR_KEY] \
      --chain-id GAIA \
      --gas-adjustment 2 \
      --gas auto
      --node https://provider-test-rpc.intento.zone/
  ```

**Opt-in to the Consumer Chain**:

- Initialize Intento in step 1 creates a new consensus key in ~/.intento/config/priv_validator_key.json. Show consensus key:

```bash
intentod tendermint show-validator
```

- Then opt-in with dedicated key:

```bash
gaiad tx provider opt-in 4 [consumer-pubkey] --from [YOUR_KEY] --chain-id GAIA --gas auto --gas-adjustment 2 --gas auto --node https://provider-test-rpc.intento.zone/
```

OR opt-in without passing a dedicated key, assign a consumer key:

```bash
gaiad tx provider assign-consensus-key [consumer-id] [consumer-pubkey] [flags]
```

**Verify Your Opt-in Status**:

```bash
gaiad q provider consumer-opted-in-validators 4 --chain-id GAIA  --node https://provider-test-rpc.intento.zone/
```

Once the opt-in is successful, you should proceed with directly setting up your node. The chain may halt in case you are not active when the ICS validator set update happens.

---

### 3. Running Your Node

You can start your node either directly or as a system service.
Before you do this, you should import the genesis file from this repo into your node (.intento/config/genesis.json). This will become available after the update-consumer transaction happens which finalizes the validator set.

#### Option A: Direct Start

Simply run:

```bash
intentod start
```

#### Option B: Using a Systemd Service (Recommended)

1. **Create a Service File**

   ```bash
   sudo nano /etc/systemd/system/intentod.service
   ```

2. **Add Configuration**

   ```ini
   [Unit]
   Description=Intento Testnet Node
   After=network.target

   [Service]
   User=[user]
   ExecStart=$(which intentod) start
   Restart=always
   RestartSec=3
   LimitNOFILE=65535

   [Install]
   WantedBy=multi-user.target
   ```

3. **Enable and Start the Service**

Reload systemd and enable your service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable intentod

# Start the node
sudo systemctl start intentod

# To stop the node
sudo systemctl stop intentod

# To view logs
sudo journalctl -u intentod -f -o cat
```

After 2/3 of the voting power runs their node, the chain produces blocks.


### 4. Create a governour

Next, you can set your node up to be a governor on the consumer chain by registering as a validator.

- **Request tokens from the faucet**:

**$request into1...**

For the account you will broadcast transactions with.

- **Retrieve Your Validator Pubkey**:
  ```bash
  intentod tendermint show-validator
  ```
- **Create a `validator.json` File**:
  ```bash
  cat <<EOF > /tmp/validator.json
  {
      "pubkey": "[PUBKEY]",
      "amount": "1200000uinto",
      "moniker": "[MONIKER]",
      "identity": "validator",
      "website": "https://intentotestnet.example.com",
      "security": "team@intentotestnet.example.com",
      "details": "Optional validator details",
      "commission-rate": "0.1",
      "commission-max-rate": "0.2",
      "commission-max-change-rate": "0.01",
      "min-self-delegation": "1"
  }
  EOF
  ```
- **Register as a Validator**:
  ```bash
  intentod tx staking create-validator \
      /tmp/validator.json \
      --from [YOUR_KEY] \
      --chain-id intento-ics-test-1 \
      --gas auto
      --gas-adjustment 2
  ```


That is it! You are now a validator on the Intento testnet.

---

## IBC Connection Information

More details regarding IBC connection parameters will be shared as they become available. Please refer to the latest testnet documentation for updates.

---

By following these detailed steps, you should be able to join the Intento testnet successfully. If you encounter any issues or need further assistance, please consult the testnet support channels.
