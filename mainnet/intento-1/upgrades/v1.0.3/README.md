---
title: Intento v1.0.3 Upgrade
order: 2
---

<!-- markdown-link-check-disable -->

# Intento v1.0.3 Upgrade, Instructions

- Chain upgrade point: `September 16th 2025, 12:00 UTC (approximately)`, at height `1096000`;
- Go version: `v1.24.6`
- Release: https://github.com/trstlabs/intento/releases/tag/v1.0.3

This document describes the steps for validators and full node operators, to upgrade successfully to the Intento v1.0.3 release. For more details on the release, please see the [release notes](https://github.com/trstlabs/intento/releases/tag/v1.0.3). This guide is based on the upgrade guide from Neutron.

## Chain-id will remain the same

The chain-id of the network will remain the same, `intento-1`. This is because an in-place migration of state will take place, i.e., this upgrade does not export any state.

### System requirement
<!-- 
- 8GB RAM is recommended to ensure a smooth upgrade.

If you have less than 8GB RAM, you might try creating a swapfile to swap an idle program onto the hard disk to free up memory. This can allow your machine to run the binary than it could run in RAM alone.

```shell
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
``` -->

- Make sure you have enough disk space for upgrade, the state can grow twice durng upgrade.

### Backups

Prior to the upgrade, validators are encouraged to take a full data snapshot. Snapshotting depends heavily on infrastructure, but generally this can be done by backing up the `.intentod` directory.
If you use Cosmovisor to upgrade, by default, Cosmovisor will backup your data upon upgrade. See below [upgrade using cosmovisor](#method-ii-upgrade-using-cosmovisor) section.

It is critically important for validator operators to back-up the `.intentod/data/priv_validator_state.json` file after stopping the intentod process. This file is updated every block as your validator participates in consensus rounds. It is a critical file needed to prevent double-signing, in case the upgrade fails and the previous chain needs to be restarted.

### Current runtime

The Intento mainnet network, `intento-1`, is currently running [Intento v1.0.2](https://github.com/trstlabs/intento/releases/tag/v1.0.2). We anticipate that operators who are running on v1.0.2, will be able to upgrade successfully. Validators are expected to ensure that their systems are up-to-date and capable of performing the upgrade. This includes running the correct binary, or if building from source, building with go `1.24`.

### Target runtime

The Intento mainnet network, `intento-1`, will run [Intento v1.0.3](https://github.com/trstlabs/intento/releases/tag/v1.0.3). Operators _**MUST**_ use this version post-upgrade to remain connected to the network.

## Upgrade steps

There are 2 major ways to upgrade a node:

- Manual upgrade
- Upgrade using [Cosmovisor](https://pkg.go.dev/cosmossdk.io/tools/cosmovisor)
    - Either by manually preparing the new binary
    - Or by using the auto-download functionality (this is not yet recommended)

If you prefer to use Cosmovisor to upgrade, some preparation work is needed before upgrade.

## Create the updated Intento binary of v1.0.3

### Go to Intento directory if present else clone the repository

```shell
   git clone https://github.com/trstlabs/intento.git
```

### Follow these steps if Intento repo already present

```shell
   cd $HOME/intento
   git pull
   git fetch --tags
   git checkout v1.0.3
   make install
```

### Check the new Intento version, verify the latest commit hash
```shell
   $ intentod version --long
   build_tags: netgo,ledger
    commit: eb637529aa11b1f4b1ab4e684fccd0e3939c81f0
    cosmos_sdk_version: v0.50.14
    go: go version go1.24.6 darwin/arm64
    name: Intento
    server_name: intentod
    version: 1.0.3
   ...
```

### Or check checksum of the binary if you decided to [download it](https://github.com/trstlabs/intento/releases/tag/v1.0.3)

```shell
$ shasum -a 256 intentod_linux_amd64_v1.0.3
eb637529aa11b1f4b1ab4e684fccd0e3939c81f0  intentod_linux_amd64_v1.0.3
```


### Make sure you are using the proper version of libwasm

You can check the version you are currently using by running the following command:
```
$ intentod q wasm libwasmvm-version

2.2.4
```
The proper version is `2.2.4`.

**If the version on your machine is different you MUST change it immediately!**

#### Ways to change libwasmvm

- Use a statically built intentod binary from an official Intento release: [https://github.com/trstlabs/intento/releases/tag/v1.0.3](https://github.com/trstlabs/intento/releases/tag/v1.0.3)
- If you built Intento binary by yourself, `libwasmvm` should be loaded dynamically in your binary and somehow, the wrong `libwasmvm` library was present on your machine. You can change it by downloading the proper one and linking it to the Intento binary manually:
1. download a proper version of `libwasmvm`:

```
$ wget https://github.com/CosmWasm/wasmvm/releases/download/v2.2.4/libwasmvm.x86_64.so
```

2. tell the linker where to find it:
```
$ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib/
```

3. check that libwasmvm version is correct:
```
$ intentod q wasm libwasmvm-version
2.2.4
```

### Method I: Manual Upgrade

Make sure Intento v1.0.3 is installed by either downloading a [compatible binary](https://github.com/trstlabs/intento/releases/tag/v1.0.3), or building from source. Building from source requires **Golang 1.24.x**.

Run Intento v1.0.1 till upgrade height, the node will panic:

```shell
ERR UPGRADE "v1.0.3" NEEDED at height: 1096000: upgrade to v1.0.3 and applying upgrade "v1.0.3" at height: 1096000
```

Stop the node, and switch the binary to **Intento v1.0.3** and re-start by `intentod start`.

It may take several minutes to a few hours until validators with a total sum voting power > 2/3 to complete their node upgrades. After that, the chain can continue to produce blocks.

### Method II: Upgrade using Cosmovisor

### Manually preparing the binary

##### Preparation

Install the latest version of Cosmovisor (`1.5.0`):

```shell
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0
```

**Verify Cosmovisor Version**

```shell
cosmovisor version
cosmovisor version: v1.5.0
```

Create a cosmovisor folder:

create a Cosmovisor folder inside `$Intento_HOME` and move Intento v1.0.3 into `$Intento_HOME/cosmovisor/genesis/bin`

```shell
mkdir -p $Intento_HOME/cosmovisor/genesis/bin
cp $(which intentod) $Intento_HOME/cosmovisor/genesis/bin
```

build **Intento v1.0.3**, and move intentod v1.0.3 to `$Intento_HOME/cosmovisor/upgrades/v1.0.3/bin`

```shell
mkdir -p  $Intento_HOME/cosmovisor/upgrades/v1.0.3/bin
cp $(which intentod) $Intento_HOME/cosmovisor/upgrades/v1.0.3/bin
```

Then you should get the following structure:

```shell
.
├── current -> genesis or upgrades/<name>
├── genesis
│   └── bin
│       └── intentod  #v1.0.1
└── upgrades
    └── v1.0.3
        └── bin
            └── intentod  #v1.0.3
```

Export the environmental variables:

```shell
export DAEMON_NAME=intentod
# please change to your own Intento home dir
# please note `DAEMON_HOME` has to be absolute path
export DAEMON_HOME=$Intento_HOME
export DAEMON_RESTART_AFTER_UPGRADE=true
```

Start the node:

```shell
cosmovisor run start --x-crisis-skip-assert-invariants --home $DAEMON_HOME
```

Skipping the invariant checks is strongly encouraged since it decreases the upgrade time significantly and since there are some other improvements coming to the crisis module in the next release of the Cosmos SDK.

#### Expected upgrade result

When the upgrade block height is reached, Intento will panic and stop.

After upgrade, the chain will continue to produce blocks when validators with a total sum voting power > 2/3 complete their node upgrades.

## Upgrade duration

Most likely it takes a couple of minutes.

## Rollback plan

During the network upgrade, core Intento team will be keeping an ever vigilant eye and communicating with operators on the status of their upgrades. During this time, the core team will listen to operator needs to determine if the upgrade is experiencing unintended challenges. In the event of unexpected challenges, the core team, after conferring with operators and attaining social consensus, may choose to declare that the upgrade will be skipped.

Steps to skip this upgrade proposal are simply to resume the intento-1 network with the (downgraded) v1.0.1 binary using the following command:

> intentod start --unsafe-skip-upgrade 1096000

Note: There is no particular need to restore a state snapshot prior to the upgrade height, unless specifically directed by core Intento team.

Important: A social consensus decision to skip the upgrade will be based solely on technical merits, thereby respecting and maintaining the decentralized governance process of the upgrade proposal's successful YES vote.

## Risks

As a validator performing the upgrade procedure on your consensus nodes carries a heightened risk of double-signing and being slashed. The most important piece of this procedure is verifying your software version and genesis file hash before starting your validator and signing.

The riskiest thing a validator can do is discover that they made a mistake and repeat the upgrade procedure again during the network startup. If you discover a mistake in the process, the best thing to do is wait for the network to start before correcting it.

## FAQ

1. Q: My node restarted in the middle of upgrade process (OOM killed, hardware issues, etc), is it safe to just proceed with the upgrade

   A: No. Most likely the upgrade will be completed successfully. But you get AppHash error after the network gets up. It's a lot safer to restart full process from scratch(recover the node from a backup).

   To perform an upgrade you need to keep your `./data/priv_validator_state.json` file when you are applying a snapshot from the backup.
   This will help you avoid the risk of slashing due to double signing.

<!-- markdown-link-check-enable -->