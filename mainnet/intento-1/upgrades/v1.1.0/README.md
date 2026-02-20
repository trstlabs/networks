---
title: Intento v1.1.0 Upgrade
order: 2
---

<!-- markdown-link-check-disable -->

# Intento v1.1.0 Upgrade, Instructions

- **Chain upgrade point**: TBD
- **Go version**: `v1.24.6` (same as previous version)
- **CometBFT version**: v0.38.19 updated.
- **Release**: https://github.com/trstlabs/intento/releases/tag/v1.1.0
- **commit**: `a2d3d3ded901872e97938762cb02f6fa4fcb6061`

This guide outlines the process for validators upgrading to Intento v1.1.0. This upgrade introduces a major change in how validators are handled, transitioning from Interchain Security (ICS) to a sovereign validator set.

## Overview

The v1.1.0 upgrade creates the sovereign validator set for the Intento chain. Existing validators participate in this migration through an opt-in process managed via an on-chain allowlist.

During the upgrade, the `DeICS` logic will execute:
1.  Migrate "governor" validators (existing validators) who have opted in.
2.  Add any new validators specified in the allowlist.
3.  Remove ICS validators.

## Prerequisites

To be included in the sovereign validator set after the upgrade, your validator must be included in the list in the binary. See https://github.com/trstlabs/intento/tree/main/app/upgrades/mainnet/v1.1.0/validators/staking for the list of validators.

## Chain ID

The chain-id of the network will remain the same, `intento-1`. This is because an in-place migration of state will take place, i.e., this upgrade does not export any state.

### System Requirements

- **RAM**: 8GB recommended for a smooth upgrade
- **Disk Space**: Ensure you have enough disk space as the state may grow during upgrade

### Backups

Before proceeding with the upgrade, validators are strongly encouraged to take a full data snapshot. This typically involves backing up the `.intentod` directory.

If you use Cosmovisor to upgrade, it will automatically back up your data during the upgrade process (see [Upgrade using Cosmovisor](#method-ii-upgrade-using-cosmovisor) section below).

> :warning: **Critical**: After stopping the `intentod` process, back up the `.intentod/data/priv_validator_state.json` file. This file is updated every block as your validator participates in consensus rounds and is crucial for preventing double-signing if the upgrade fails and the previous chain needs to be restarted.

### Current Runtime

The current Intento mainnet network, `intento-1`, is running [Intento v1.0.9](https://github.com/trstlabs/intento/releases/tag/v1.0.9). Validators should ensure their systems are up-to-date and capable of performing the upgrade.

### Target Runtime

The upgraded Intento mainnet network, `intento-1`, will run [Intento v1.1.0](https://github.com/trstlabs/intento/releases/tag/v1.1.0). All operators **MUST** use this version post-upgrade to remain connected to the network.

## Upgrade Steps

### Method I: Manual Upgrade

1. **Stop your node** when the chain reaches the upgrade height or when instructed by the team.
   ```bash
   sudo systemctl stop intentod
   ```

2. **Back up your validator state**
   ```bash
   cp ~/.intentod/data/priv_validator_state.json ~/priv_validator_state.json.backup
   ```

3. **Install the new version**
   ```bash
   # Download the new binary
   cd ~/go/bin
   wget https://github.com/trstlabs/intento/releases/download/v1.1.0/intentod_linux_amd64_v1.1.0 -O intentod
   chmod +x intentod
   ```

4. **Verify the version**
   ```bash
   ./intentod version
   # Should output: 1.1.0
   ```

5. **Restart your node**
   ```bash
   sudo systemctl start intentod
   ```

### Method II: Upgrade using Cosmovisor

1. **Ensure Cosmovisor is set up** as described in the [main README](../README.md#cosmovisor-setup).

2. **Build or download the new binary**
   ```bash
   mkdir -p ~/.intentod/cosmovisor/upgrades/v1.1.0/bin
   cd ~/.intentod/cosmovisor/upgrades/v1.1.0/bin
   wget https://github.com/trstlabs/intento/releases/download/v1.1.0/intentod_linux_amd64_v1.1.0 -O intentod
   chmod +x intentod
   ```

3. **Verify the binary**
   ```bash
   ./intentod version
   # Should output: 1.1.0
   ```

4. **Restart Cosmovisor**
   ```bash
   sudo systemctl restart cosmovisor
   ```

## Post-Upgrade Verification

After the upgrade, verify that:

1. Your node is syncing blocks
2. The version is correct:
   ```bash
   intentod version
   # Should output: 1.1.0
   ```
3. Your validator is signing blocks (if you're a validator)


##  1.1.0 POST-ICS Upgrade-specific Verification

After the upgrade, verify your validator status:

```bash
intentod query staking validators
```

You should see your validator with status `BOND_STATUS_BONDED`.

## Troubleshooting

If your validator was not migrated:
1.  Check if your JSON file was correctly merged into the release.
2.  Verify your `valoper` address matches the one in the JSON file.
3.  Ensure you are not jailed before the upgrade.

## Rollback Plan

In case of critical issues, the following steps can be taken to rollback to v1.0.9:

1. Stop the node
2. Restore the previous binary
3. Reset the application state (if necessary)
4. Restart the node

> **Note**: The exact rollback procedure may vary depending on the nature of the issue. Follow the instructions provided by the Intento team in case a rollback is required.

## Support

If you encounter any issues during the upgrade, please reach out to the Intento team on [Discord](https://discord.gg/intento) or open an issue on [GitHub](https://github.com/trstlabs/intento/issues).

