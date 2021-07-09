#!/bin/bash

APPROVAL_PROG=../assets/approve_program.teal

# Generate the group transaction without sending it
./call_nosend_smart_contract.sh

# Generate the context debug file
goal clerk dryrun -t signout.tx --dryrun-dump -o dr.msgp

# The smart contract transaction is at index 1 within the group
tealdbg debug $APPROVAL_PROG -d dr.msgp --group-index 1 --frontend web
