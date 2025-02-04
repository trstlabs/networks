Below is an updated guide tailored for the Intento testnet. The testnet uses:

- **Chain ID**: `intento-ics-test-1`
- **Binary**: `intentod`
- **Consumer ID**: N/A

This guide is based on the [Elys Network network repository](https://github.com/elys-network/networks) but has been adapted for Intento. Follow the steps below to set up your node.

---

# Joining the Intento Testnet (ICS)

Welcome to the Intento testnet! This guide will walk you through setting up a full node and joining the testnet. The testnet is designed to test Interchain Security (ICS) functionality and ensure overall network stability.

## Quick Reference

- **Consumer ID**: TBA
- **Chain ID**: `intento-ics-test-1`

## Hardware Requirements

| Component   | Minimum Specification |
| ----------- | --------------------- |
| **CPU**     | 4 cores               |
| **RAM**     | 16 GB                 |
| **Storage** | 200 GB SSD            |
| **Network** | 100 Mbps+             |

## Software Requirements

- **Operating System**: Ubuntu 20.04+ or macOS
- **Go**: v1.22.7 or later

---

## Node Setup Instructions

_Note: Although many steps are similar to the other ICS testnet setups, all commands and configurations below have been updated for the Intento testnet._

### 1. Validator-Specific Information

For validators: The typical consumer chain opt-in step is not required because the Consumer ID is not applicable for this testnet.

### 2. Node Setup Options

#### Option A: Quick Setup Script

An example setup script is available to automate installation:

```bash
wget https://raw.githubusercontent.com/trstlabs/networks/main/testnet/intento-ics-test-1/create_node.sh
chmod +x create_node.sh
./create_node.sh "your-moniker-name"
```

> **⚠️ Important Note for Validators**:
>
> 1. **Review the Script**: Before running, confirm that the script does not automatically start the node. Adjust if necessary.
> 2. **Key Replacement**: If you are a validator, replace the generated key at `$HOME/.intento/config/priv_validator_key.json` with your actual testnet key file.
> 3. **Timing**: Only start the node after replacing your key to prevent any risk of double signing.

#### Option B: Manual Setup

1. **Clone the Repository and Build the Binary**

Clone the Intento repository and build the binary:

```bash
git clone https://github.com/trstlabs/intento.git
cd intento
git checkout main
make install
```

This will install the `intentod` binary. Initialize your node with:

```bash
intentod init [your-moniker] --chain-id intento-ics-test-1
```

2. **Configure Your Node**

a. **Download the Genesis File**

Download the genesis file to set up your node configuration:

```bash
curl -o $HOME/.intento/config/genesis.json https://raw.githubusercontent.com/trstlabs/networks/main/testnet/intento-ics-test-1/genesis.json
```

b. **Replace the Validator Key (For Validators Only)**

If you are running a validator, replace the auto-generated key with your actual testnet key:

```bash
mv /path/to/your/priv_validator_key.json $HOME/.intento/config/priv_validator_key.json
```

c. **Edit Node Settings**

- **Persistent Peers & Seeds**: Update the `config.toml` file located at `$HOME/.intento/config/config.toml` with persistent peers and seeds as specified by the testnet docs.
- **Minimum Gas Prices**: Edit `$HOME/.intento/config/app.toml` to set the minimum gas prices. For example:

  ```toml
  minimum-gas-prices = "0.003uinto,0.001ibc/<IBC_DENOM>"
  ```

  Replace `<IBC_DENOM>` with the proper denomination provided in further testnet documentation.

d. **Optional: Governor Registration**

If you wish to register as a governor, follow these steps:

- **Retrieve Your Validator Pubkey**:

  ```bash
  intentod cometbft show-validator
  ```

- **Create a `governor.json` File**:

  ```bash
  cat <<EOF > /tmp/governor.json
  {
      "pubkey": "[PUBKEY]",
      "amount": "10000000uinto",
      "moniker": "[MONIKER]",
      "identity": "Intento governor",
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

- **Register as a Governor**:

  ```bash
  intentod tx staking create-validator \
      /tmp/governor.json \
      --from [YOUR_KEY] \
      --chain-id intento-ics-test-1 \
      --fees 20000uinto \
      --gas auto
  ```

---

### 3. Running Your Node

You can start your node either directly or as a system service.

#### Option A: Direct Start

Simply run:

```bash
intentod start
```

#### Option B: Using a Systemd Service (Recommended)

1. **Create a Service File**

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/intentod.service
```

2. **Add the Following Configuration**

Replace `[user]` with your Linux username:

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

3. **Enable and Manage the Service**

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

---

## IBC Connection Information

More details regarding IBC connection parameters will be shared as they become available. Please refer to the latest testnet documentation for updates.

---

By following these detailed steps, you should be able to join the Intento testnet successfully. If you encounter any issues or need further assistance, please consult the testnet support channels.
