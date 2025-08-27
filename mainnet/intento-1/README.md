# **Joining the Intento Mainnet (ICS)**

This is the **Intento Consumer Chain** (Consumer ID `22`) under Cosmos Hub’s **Interchain Security (ICS)**.
If you’ve run ICS consumers like Neutron, Stride, or Elys, this will feel familiar — but read carefully.
Spawn time is critical.

---

## **Before You Start**

- **Allowlist**: Only allowlisted Hub validators can join. If you’re active on Hub mainnet and not on the list, contact us on Discord.
- **Provider Requirement**: You must run a synced **Cosmos Hub node** and be in the **active set** or top 20 inactive.
- **Spawn Time**: If you’re not opted in and synced before spawn, you’ll miss inclusion and may be slashed.
- **Consumer ID**: `22`
- **Chain ID**: `intento-1`
- **Binary**: `intentod`
- **ICS Parameters**: See [Forge](https://forge.cosmos.network/chain/22)
- **Genesis Hash** 45428d023b0dd3633e5eab51aa940ed8375900f6b9a7fcb604157e04832f2a4d
---

## **1. Prepare the Consumer Node**

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
git checkout v1.0.1
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

**Replace Validator Key (validators only):**

Only in case of reusing private key, not recommended. Optional.
```bash
mv /path/to/priv_validator_key.json \
   $HOME/.intento/config/priv_validator_key.json
```

_Do this **before** starting node to avoid double signing._

**Configure Networking:**

```bash
PEERS="06bf7c52e0584d91a9d7c9f71141f246c3347d5a@144.126.208.31:26656"
SEED="3a1d847563a1ea3b3e6195c3e4f9e90d9b4f7b56@tenderseed.ccvalidators.com:29111" 

config="$HOME/.intento/config/config.toml"
app="$HOME/.intento/config/app.toml"
client="$HOME/.intento/config/client.toml"

ATOM="ibc/C4CFF46FD6DE35CA4CF4CE031E643C8FDC9BA4B99AE598E9B0ED98FE3A2319F9" # ATOM on intento-1 assuming ibc transfer channel 1from cosmoshub-4. Placeholder, may need to be replaced with actual hash.
OSMO="ibc/13B2C536BB057AC79D5616B8EA1B9540EC1F2170718CAFF6F0083C966FFFED0B" # OSMO on intento-1 assuming ibc transfer channel 2 from osmosis-1. Placeholder, may need to be replaced with actual hash.

sed -i "s|^seeds *=.*|seeds = \"$SEED\"|" $config
sed -i "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $config
sed -i "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.005uinto,0.001$ATOM\,0.005$OSMO\"|" $app
sed -i "s|^chain-id *=.*|chain-id = \"intento-1\"|" $client
```

---

## **2. Opt-in on Cosmos Hub**

**Build Gaia:**

```bash
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout v25.1.0
make install
gaiad version
```

**Get Consumer Consensus Pubkey:**

```bash
intentod tendermint show-validator
```

**Opt-in (replace `[YOUR_KEY]`):**

Recommended here to pass in the consumer pubkey as an argument (not having [consumer-pubkey] means reusing the Cosmos Hub validator pubkey).

```bash
gaiad tx provider opt-in 22 [consumer-pubkey] \
  --from [YOUR_KEY] \
  --chain-id cosmoshub-4 \
  --gas auto --gas-adjustment 2 \
  --node https://rpc.cosmos.directory/cosmoshub
```

**Verify Opt-in:**

```bash
gaiad q provider consumer-opted-in-validators 22 \
  --chain-id cosmoshub-4 \
  --node https://rpc.cosmos.directory/cosmoshub
```

---

## **3. Start the Consumer Node**

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

Once 2/3 Hub voting power is running, blocks will produce.

---

## **4. Register as Consumer Validator (Governor)**

_After update-consumer runs and validator set is finalized._

**Get INTO tokens** (from testnet points or request via Discord/email).

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
  --min-self-delegation "1" \
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

**3. Channels**

- **Cosmos Hub to Intento** — channel-x
- **Intento to Cosmos Hub** — channel-1

**4. Monitor & Maintain**

- Keep Hermes running with systemd or a supervisor.
- Watch for failed packets and client expiry in logs.
- Adjust `max_gas` and `max_msg_num` if network load spikes.

## **Final Notes**

- Always keep provider and consumer nodes in sync.
- Avoid key reuse across environments to prevent double signing.
- Monitor spawn schedule closely — missed spawn = missed rewards + possible slash.


## Node Info

RPC:
https://rpc-mainnet.intento.zone:443
https://rpc.intento.ccnodes.com:443

LCD:
https://lcd-mainnet.intento.zone:443
https://api.intento.ccnodes.com:443

GRPC:
grpc.intento.ccnodes.com:443