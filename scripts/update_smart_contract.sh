#!/bin/bash

# Change the account address to an account under your control, this will be the onwer
CREATOR=QQSWFKMFBLSR5WKZJVDMRIP5VKF5QBET437WGMPCWYINQGX3KB534OGVLY
APP_ID=70
APPROVAL_PROG=../assets/approval_program.teal
CLEAR_PROG=../assets/clear_program.teal

# Make the approval program
python3 ../assets/approval_program.py > ../assets/approval_program.teal

goal app update --app-id 53 --from $CREATOR --approval-prog $APPROVAL_PROG --clear-prog $CLEAR_PROG
