# **Joining the Intento Mainnet (GG-PoS)**

This is the **Intento Chain**.
If you’ve run Cosmos SDK-based chains with PoS, this will feel familiar.

---

## **Before You Start**

- **Governance-gated PoS**: Only governance-approved validators can join under our [GG-PoS](https://docs.intento.zone/reference/consensus) mechanism.


- **Chain ID**: `intento-1`
- **Binary**: `intentod`
- **Genesis Hash** 45428d023b0dd3633e5eab51aa940ed8375900f6b9a7fcb604157e04832f2a4d

## **1. Prepare the Node**

**Hardware Minimums:**

| CPU     | RAM   | Storage    | Network   |
| ------- | ----- | ---------- | --------- |
| 4 cores | 16 GB | 200 GB SSD | 100 Mbps+ |

**Software:**

- Linux 20.04+
- Go 1.24.6+
- wasmvm v2.2.4

**Build Binary:**

```bash
git clone https://github.com/trstlabs/intento.git
cd intento
git checkout v1.1.0
make install
intentod version
```

**Init Consumer Config:**

```bash
intentod init [moniker] --chain-id intento-1
```

**Download Genesis (placeholder until update-consumer executes):**

```bash
curl -o $HOME/.intento/config/genesis.json \
  https://raw.githubusercontent.com/trstlabs/networks/main/mainnet/intento-1/genesis.json
```

**Configure Networking:**

```bash
PEERS="06bf7c52e0584d91a9d7c9f71141f246c3347d5a@144.126.208.31:26656"
SEED=" 

config="$HOME/.intento/config/config.toml"
app="$HOME/.intento/config/app.toml"
client="$HOME/.intento/config/client.toml"

ATOM="ibc/C4CFF46FD6DE35CA4CF4CE031E643C8FDC9BA4B99AE598E9B0ED98FE3A2319F9" 
OSMO="ibc/47BD209179859CDE4A2806763D7189B6E6FE13A17880FE2B42DE1E6C1E329E23"

sed -i "s|^seeds *=.*|seeds = \"$SEED\"|" $config
sed -i "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $config
sed -i "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.005uinto,0.001$ATOM\,0.005$OSMO\"|" $app
sed -i "s|^chain-id *=.*|chain-id = \"intento-1\"|" $client
```


## **3. Start the Node**

**Direct Run:**

```bash
intentod start
```

**Systemd (recommended):**

```bash
sudo tee /etc/systemd/system/intentod.service <<EOF
[Unit]
Description=Intento Consumer Node
After=network.target

[Service]
User=$USER
ExecStart=$(which intentod) start
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable intentod
sudo systemctl start intentod
journalctl -u intentod -f -o cat
```



## **4. Register as Validator 
**Get INTO tokens** .

**Pubkey:**

```bash
intentod tendermint show-validator
```

**Create Validator:**

```bash
intentod tx staking create-validator \
  --pubkey "[PUBKEY]" \
  --amount 1200000uinto \
  --moniker "[MONIKER]" \
  --identity "validator" \
  --website "https://example.com" \
  --security-contact "team@example.com" \
  --details "Optional details" \
  --commission-rate "0.1" \
  --commission-max-rate "0.2" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "2000000" \
  --from [YOUR_KEY] \
  --chain-id intento-1 \
  --gas auto --gas-adjustment 2
```

---

## **5. Run an IBC Relayer (Optional Incentives)**

Relayers earn rewards (5% of new token supply is distributed to active relayers for flow execution).
If you want to contribute to network connectivity and get rewarded, run a Hermes relayer.

**1. Install Hermes**
Follow the official guide: [Hermes Docs](https://hermes.informal.systems/)

**2. Recommended Settings**
In your Hermes config (typically `~/.hermes/config.toml`), apply conservative but high-throughput parameters to avoid stuck packets while preventing excessive gas burn.

Example snippet for a host chain `osmosis-1`:

```toml
event_source = { mode = 'pull', interval = '5000ms', max_retries = 2 }
rpc_timeout = '120s'
account_prefix = 'osmo'
key_name = 'relayer-osmo'
store_prefix = 'ibc'

default_gas = 500000
max_gas = 25000000
gas_multiplier = 1.5
max_msg_num = 10
max_tx_size = 2000000

clock_drift = '40s'
max_block_time = '30s'
client_refresh_rate = '1/200'
```

**3. IBC Channels**

- **Cosmos Hub to Intento** — channel-1490
- **Intento to Cosmos Hub** — channel-1

More: https://explorer.intento.zone/intento-mainnet/ibc

**4. Monitor & Maintain**

- Keep Hermes running with systemd or a supervisor.
- Watch for failed packets and client expiry in logs.
- Adjust `max_gas` and `max_msg_num` if network load spikes.

## **Final Notes**

- Always keep provider and consumer nodes in sync.
- Avoid key reuse across environments to prevent double signing.
- Monitor spawn schedule closely — missed spawn = missed rewards + possible slash.


## Endpoints

RPC:
https://rpc-mainnet.intento.zone:443

REST:
https://lcd-mainnet.intento.zone:443
