
This guide is based on the [Elys Network network repository](https://github.com/elys-network/networks) but has been adapted for Intento. Follow the steps below to set up your node.

- **Chain ID**: `intento-ics-test-1`
- **Binary**: `intentod`
- **Consumer ID**: N/A


---

# Joining the Intento Testnet (ICS)

Welcome to the Intento testnet! This guide will walk you through setting up a full node and joining the testnet. The testnet is designed to test Interchain Security functionality and ensure overall network stability.

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

## Node Setup Instructions

### 1. Node Setup Options

#### Option A: Quick Setup Script

```bash
wget https://raw.githubusercontent.com/trstlabs/networks/main/testnet/intento-ics-test-1/create_node.sh
chmod +x create_node.sh
./create_node.sh "your-moniker-name"
```

> **⚠️ Important Note for Validators**:
>
> - Review the script before running it.
> - Replace the generated key at `$HOME/.intento/config/priv_validator_key.json` with your actual testnet key.
> - Start the node only after replacing your key to prevent double signing.

#### Option B: Manual Setup

1. **Clone the Repository and Build the Binary**

   ```bash
   git clone https://github.com/trstlabs/intento.git
   cd intento
   git checkout main
   make install
   ```

   Initialize your node:

   ```bash
   intentod init [your-moniker] --chain-id intento-ics-test-1
   ```

2. **Configure Your Node**

   - **Download the Genesis File**:
     ```bash
     curl -o $HOME/.intento/config/genesis.json https://raw.githubusercontent.com/trstlabs/networks/main/testnet/intento-ics-test-1/genesis.json
     ```
   - **Replace Validator Key (For Validators Only)**:
     ```bash
     mv /path/to/your/priv_validator_key.json $HOME/.intento/config/priv_validator_key.json
     ```
   - **Edit Node Settings**:
     Update `$HOME/.intento/config/config.toml` with persistent peers and seeds from testnet docs.

3. **Fake Cosmos Hub Registration** (Required for ICS Testing)

Before setting up your node, validators must opt-in\* to the Intento testnet via a fake Cosmos Hub. Follow these steps:

- **Retrieve Your Validator Pubkey**:
  ```bash
  gaiad cometbft show-validator
  ```
- **Create a `validator.json` File**:
  ```bash
  cat <<EOF > /tmp/validator.json
  {
      "pubkey": "[PUBKEY]",
      "amount": "10000000uatom",
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
      --fees 20000uatom \
      --gas auto
      --node https://provider-test-rpc.intento.zone/
  ```

**Opt-in to the Consumer Chain**:

```bash
gaiad tx provider opt-in intento-ics-test-1 --from [YOUR_KEY] --chain-id GAIA --fees 5000uatom --gas auto --node https://provider-test-rpc.intento.zone/
```

**Verify Your Opt-in Status**:

```bash
gaiad q provider consumer-opt-in intento-ics-test-1 --chain-id GAIA  --node https://provider-test-rpc.intento.zone/
```

Once the opt-in is successful, you can proceed with setting up your node.

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

4. **Enable and Manage the Service**

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
