#!/bin/bash

# Change the account address to an account under your control, this will be the onwer
CREATOR=QQSWFKMFBLSR5WKZJVDMRIP5VKF5QBET437WGMPCWYINQGX3KB534OGVLY
APPROVAL_PROG=../assets/approval_program.teal
CLEAR_PROG=../assets/clear_program.teal

# Make the approval program
python3 ../assets/approval_program.py > ../assets/approval_program.teal

goal app create --creator $CREATOR --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 --approval-prog $APPROVAL_PROG --clear-prog $CLEAR_PROG 
