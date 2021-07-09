#!/bin/bash

# Generate the group transaction without sending it
./call_nosend_smart_contract.sh

goal clerk rawsend --filename signout.tx
