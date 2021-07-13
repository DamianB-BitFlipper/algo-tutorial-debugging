# Scripts Usage

## Overview

This directory contains a few shell scripts which help manage and interface with the smart contract. Their purpose and effects are listed below.

- `call_nosend_smart_contract.sh`: Create a transaction group which decrements the `counter`. Saves the transaction data to file without sending it out to the network.
- `call_smart_contract.sh`: Create a transaction group which decrements the `counter`. Sends the transaction group to the network, triggering the bug if `counter == 0`.
- `debug_smart_contract.sh`: Create a transaction group which decrements the `counter`. Launches the `tealdbg` debugger on the smart contract TEAL code with the appropriate debugger context. The debugger can be used to investigate the bug if `counter == 0`.
- `delete_smart_contract.sh`: Deletes the smart contract from the network.
-  `deploy_smart_contract.sh`: Compiles the buggy PyTEAL code and deploys the smart contract.
- `read_state_smart_contract.sh`: Prints the global variables of the smart contract.
- `update_smart_contract.sh`: Compiles the buggy PyTEAL code and issues an updated smart contract to the network.

## Minimal Usage
1. Deploy the smart contract: `deploy_smart_contract.sh`
2. Record the printed `APP_ID` from above in `call_nosend_smart_contract.sh, delete_smart_contract.sh, read_state_smart_contract.sh, update_smart_contract.sh`
3. Trigger the bug and debug the smart contract: `debug_smart_contract.sh`