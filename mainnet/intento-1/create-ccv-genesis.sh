#!/bin/bash

gaiad --node https://rpc.cosmos.directory/cosmoshub query provider consumer-genesis 22 -o json > ccv.json
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' genesis-without-ccv.json ccv.json > genesis.json
#rm ccv.json
sha256sum genesis.json
