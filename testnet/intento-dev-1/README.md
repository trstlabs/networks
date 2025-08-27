Here’s a clean **Intento Devnet** guide in the same ICS-proven validator/dev style as the mainnet one, but adapted for testing.
I’ve kept it short where possible and linked out where instructions aren’t specific to us.

---

# **Joining the Intento Devnet (ICS)**

The Intento Devnet is connected to our local **Cosmos Hub Devnet** via **Interchain Security**.
You can join as:

* **Governor** (validator on Intento devnet chain)
* **Node Operator** (non-validator full node)
* **IBC Relayer**
* **Validator** (validator on Cosmos Hub devnet chain)

Validators must:

1. Run both a **provider node** (Gaia Devnet)
2. Opt-in to **Consumer ID 1** on the provider
3. Run a synced **consumer node** (Intento Devnet)

---

## **1. Network Info**

**Intento Devnet (Consumer Chain)**

* Chain ID: `intento-dev-1`
* Binary: `intentod`
* RPC: [https://rpc-devnet.intento.zone](https://rpc-devnet.intento.zone)
* API: [https://api-devnet.intento.zone](https://api-devnet.intento.zone)
* Explorer: [https://explorer.intento.zone](https://explorer.intento.zone)
* Version: see [Intento repo pre-releases](https://github.com/trstlabs/intento)

**Provider (Gaia Devnet)**

* Chain ID: `gaia-devnet`
* RPC: [https://rpc-cosmoshub-devnet.intento.zone](https://rpc-cosmoshub-devnet.intento.zone)
* API: [https://api-cosmoshub-devnet.intento.zone](https://api-cosmoshub-devnet.intento.zone/)
* Faucet:

  * Discord: `$request into1…` or `$request cosmos1…` in `#testnet-faucet`
* Gaia Version: [Check here](https://github.com/trstlabs/intento/blob/main/dockernet/dockerfiles/Dockerfile.gaia)
---

## **2. Prepare Provider Node (Gaia Devnet)**

If you’re already familiar with Gaia:

```bash
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout <current-devnet-version>
make install
gaiad version
```

**Genesis:**

```bash
curl -o ~/.gaia/config/genesis.json \
  https://files.polypore.xyz/gaia-devnet/genesis.json
```

**Config:**

```bash
SEED=""
sed -i "s|^seeds *=.*|seeds = \"$SEED\"|" ~/.gaia/config/config.toml
```

Start the node (systemd or direct). Wait until fully synced.

---

## **3. Prepare Consumer Node (Intento Devnet)**

**Build Binary:**

```bash
git clone https://github.com/trstlabs/intento.git
cd intento
git checkout <latest-pre-release>
make install
intentod version
```

**Init:**

```bash
intentod init [moniker] --chain-id intento-dev-1
```

**Genesis:**

```bash
curl -o ~/.intento/config/genesis.json \
  https://raw.githubusercontent.com/trstlabs/networks/main/devnet/intento-dev-1/genesis.json
```

**Peers & Seeds:** (ask in Discord)

```bash
sed -i "s|^seeds *=.*|seeds = \"$SEED\"|" ~/.intento/config/config.toml
sed -i "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" ~/.intento/config/config.toml
```

---

## **4. Opt-in on Provider (Consumer ID 1)**

Get your consumer consensus pubkey:

```bash
intentod tendermint show-validator
```

Opt-in:

```bash
gaiad tx provider opt-in 1 [consumer-pubkey] \
  --from [YOUR_KEY] \
  --chain-id gaia-devnet \
  --gas auto --gas-adjustment 2 \
  --node https://rpc-cosmoshub-devnet.intento.zone
```

Verify:

```bash
gaiad q provider consumer-opted-in-validators 1 \
  --chain-id gaia-devnet \
  --node https://rpc-cosmoshub-devnet.intento.zone
```

---

## **5. Start Consumer Node**

Direct:

```bash
intentod start
```

Systemd:

```bash
sudo tee /etc/systemd/system/intentod.service <<EOF
[Unit]
Description=Intento Devnet Node
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

---

## **6. Become a Governor (Validator on Consumer)**

Fund your consumer address from the faucet (`$request into1…` in Discord).
Then:

```bash
intentod tx staking create-validator \
  --pubkey "[PUBKEY]" \
  --amount 1000000uinto \
  --moniker "[MONIKER]" \
  --commission-rate "0.1" \
  --commission-max-rate "0.2" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1" \
  --from [YOUR_KEY] \
  --chain-id intento-dev-1 \
  --gas auto --gas-adjustment 2
```

---

## **7. IBC Relayer Setup (Optional)**

Use **Hermes**: [Hermes Docs](https://hermes.informal.systems/).
Recommended config snippet:

```toml
event_source = { mode = 'pull', interval = '5000ms', max_retries = 2 }
rpc_timeout = '120s'
account_prefix = 'osmo'
key_name = 'relayer-osmo02'
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

Post-spawn, we’ll publish the channel IDs for Hub ↔ Intento Devnet.

---

Do you want me to also **add a spawn timeline diagram for the devnet** like I did for mainnet? It’ll make the opt-in → update-consumer → spawn process crystal clear for testers.
