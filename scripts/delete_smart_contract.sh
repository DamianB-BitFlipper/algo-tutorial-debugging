#!/bin/bash

# Change the account address to an account under your control, this will be the onwer
CREATOR=QQSWFKMFBLSR5WKZJVDMRIP5VKF5QBET437WGMPCWYINQGX3KB534OGVLY
APP_ID=70

goal app delete --app-id $APP_ID --from $CREATOR
