![image](https://github.com/user-attachments/assets/0bd44452-5979-46d6-a10a-e4f0419e3129)

# Intento Networks

This repository contains chain configurations and setup instructions for running nodes and validators on `Intento`.

## Table of Contents

- [Intento Networks](#intento-networks)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Installation](#installation)
  - [Chain Configurations](#chain-configurations)
  - [Support](#support)
  - [Contributing](#contributing)
  - [Learn more](#learn-more)

---

## Overview

This repository provides essential resources for node operators and validators participating in the `Intento` network. It includes configuration files, scripts, and guidelines to help streamline the setup process. It is based and inspired from the Elys Network networks repo and others.

## Installation

Each network directory contains an example installation script (`create_node.sh`) to automate the setup. To install a node for a specific network, navigate to the respective network directory and run:

```bash
cd <network-directory>
chmod +x create_node.sh
./create_node.sh
```

This script will install dependencies, download the required binaries, and configure the node accordingly. For validators, it is also necesarry to opt-in to the consumer chain. More information is available in the respective network's README.

## Chain Configurations

Each network directory contains:

- `genesis.json` – Initial chain state
- `addrbook.json` – Peer addresses for network connectivity

Make sure to update these files according to the latest network requirements.

## Support

For any issues, reach out via:

- GitHub Issues
- Community Discord
- Official documentation

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a new branch.
3. Commit your changes.
4. Submit a pull request.

Ensure your changes align with the repository’s structure and follow best practices.

## Learn more

[Intento documentation](https://docs.intento.zone)

Other useful links

- [Intento website](https://intento.zone/)
- [Discord](https://discord.gg/hsVf9sYyZW)
- [TriggerPortal - one-stop tool for intent-based flows](https://triggerportal.zone/)
- [Block Explorer](https://explorer.intento.zone/)
- [Testnet Points Program ](https://github.com/trstlabs/intento-testnet-points-program)
- [Networks repository](https://github.com/trstlabs/networks)
- [TRST Labs website](https://trstlabs.xyz/)
