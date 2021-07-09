#!/bin/bash

# Change these account addresses to an accounts under your control
CREATOR=QQSWFKMFBLSR5WKZJVDMRIP5VKF5QBET437WGMPCWYINQGX3KB534OGVLY
ACCOUNT2=WWYNX3TKQYVEREVSW6QQP3SXSFOCE3SKUSEIVJ7YAGUPEACNI5UGI4DZCE
APP_ID=53

# Create the unsigned transactions 
goal clerk send --amount 0 --from $ACCOUNT2 --to $CREATOR --out ./unsginedtransaction1.tx --fee 10000000
goal app call --app-id $APP_ID --from $ACCOUNT2 --out ./unsginedtransaction2.tx

# Atomically group the transactions
cat unsginedtransaction1.tx unsginedtransaction2.tx > combinedtransactions.tx
goal clerk group -i combinedtransactions.tx -o groupedtransactions.tx

# Sign the group transaction
goal clerk sign -i groupedtransactions.tx -o signout.tx
