# Debugging and Algorand Smart Contract

## Overview

This tutorial will cover debugging a stateful smart contract using `tealdbg`, the TEAL debugger. The smart contract in this tutorial is a simple program with an intentional bug. The `tealdbg` will be used to uncover the bug and fix it.

The smart contract is written in PyTEAL and interfaced with the `goal` program.

## Requirements

- Access to an Algorand network and at least two funded accounts
- PyTEAL
- `goal`
- `tealdbg`
- Chrome web-browser (other browsers are possible, but experience is not as good)

## (Buggy) Smart Contract

The following is the PyTEAL code for a simple stateful smart contract. The smart contract records an owner address (the creator) during initialization. It then keeps track of a counter value. Whenever the onwer receives a transaction with >= 10 ALGOs, the counter will be incremented, otherwise it will be decremented. This functionality is executed as a group transaction where the first transaction is the payment to the owner and the second, the call to the smart contract.

```python
from pyteal import *

var_owner = Bytes("owner")
var_counter = Bytes("counter")

def buggy_program():
    """
    This is a stateful smart contract with a purposeful bug.
    It is used to demonstrate using the debugger to uncover the bug.
    """
    init_contract = Seq([
        App.globalPut(var_owner, Txn.sender()),
        App.globalPut(var_counter, Int(0)),
        Return(Int(1))
    ])

    is_owner = Txn.sender() == App.globalGet(var_owner)

    # Assign the transactions to variables
    payment_txn = Gtxn[0]
    app_txn = Txn # This transaction is at index 1

    payment_check = payment_txn.type_enum() == TxnType.Payment
    payment_receiver_check = payment_txn.receiver() == App.globalGet(var_owner)
    app_check = app_txn.type_enum() == TxnType.ApplicationCall

    group_checks = And(
        payment_check,
        payment_receiver_check,
        app_check,
    )

    counter = App.globalGet(var_counter)
    increment_counter  = Seq([
        Assert(group_checks),
        # Increment the counter if the sender sends the owner more than 10 Algos.
        # Otherwise decrement the counter
        If(payment_txn.amount() >= Int(10 * 1000000),
           App.globalPut(var_counter, counter + Int(1)),
           App.globalPut(var_counter, counter - Int(1)),
        ),

        Return(Int(1))
    ])

    program = Cond(
        [Txn.application_id() == Int(0), init_contract],
        [Txn.on_completion() == OnComplete.DeleteApplication, Return(is_owner)],
        [Txn.on_completion() == OnComplete.UpdateApplication, Return(is_owner)],
        [Txn.on_completion() == OnComplete.OptIn, Return(Int(1))],
        [Txn.on_completion() == OnComplete.CloseOut, Return(Int(1))],
        [Txn.on_completion() == OnComplete.NoOp, increment_counter],
    )

    return program

if __name__ == "__main__":
    print(compileTeal(buggy_program(), Mode.Application))
```

This stateful smart contract has two important code blocks `init_contract` and `increment_counter`. 

The `init_contract` block is called during contract deployment and simply initializes the owner and counter global variables.
```python
init_contract = Seq([
    App.globalPut(var_owner, Txn.sender()),
    App.globalPut(var_counter, Int(0)),
    Return(Int(1))
])
```

The `increment_counter` block is executed during any normal application call. It performs the logic which checks if the owner is receiving more or less than 10 ALGOs and increments/decrements the counter respectively.

It begins by checking the structure of the group transaction, that the first transaction is a payment transaction to the onwer and that the second transaction is an application call to this smart contract.
```python
# Assign the transactions to variables
payment_txn = Gtxn[0]
app_txn = Txn # This transaction is at index 1

payment_check = payment_txn.type_enum() == TxnType.Payment
payment_receiver_check = payment_txn.receiver() == App.globalGet(var_owner)
app_check = app_txn.type_enum() == TxnType.ApplicationCall

group_checks = And(
    payment_check,
    payment_receiver_check,
    app_check,
)
```

Second, it performs the increment/decrement accordingly.

```python
counter = App.globalGet(var_counter)
increment_counter  = Seq([
    Assert(group_checks),
    # Increment the counter if the sender sends the owner more than 10 Algos.
    # Otherwise decrement the counter
    If(payment_txn.amount() >= Int(10 * 1000000),
       App.globalPut(var_counter, counter + Int(1)),
       App.globalPut(var_counter, counter - Int(1)),
    ),

    Return(Int(1))
])
```

There is a bug in this smart contract, but where?!? If you are used to writing TEAL smart contracts, you may be able to spot it, but this bug is honetly inconspicious.

## Exposing the Bug

### Deploying the Smart Contract

Before we can call the smart contract to see the effects of the bug, we must deploy the smart contract. This call will return the `APP_ID` of the smart contract; be sure to remember it for later.

```bash
# Make the approval program
python3 approval_program.py > approval_program.teal

goal app create --creator <OWNER> --global-byteslices 1 --global-ints 1 --local-byteslices 0 --local-ints 0 --approval-prog approval_program.teal --clear-prog clear_program.teal
```

### Non-buggy Smart Contract Call

Once the smart contract is deployed, let's call it normally. This call will not expose the bug. Recall, in order to call the contract, it will have to be as a group transaction where the first transaction is a payment to the owner and the second transaction is the call to the smart contract. These transactions are created individually, grouped together, signed and then sent.

```bash
# Create the unsigned transactions
goal clerk send --amount 10000000 --from <ACCOUNT2> --to <OWNER> --out ./unsginedtransaction1.tx    # Sends 10 ALGOs to OWNER
goal app call --app-id <APP_ID> --from <ACCOUNT2> --out ./unsginedtransaction2.tx

# Atomically group the transactions
cat unsginedtransaction1.tx unsginedtransaction2.tx > combinedtransactions.tx
goal clerk group -i combinedtransactions.tx -o groupedtransactions.tx

# Sign the group transaction (Can be signed as a whole since it is coming from the same sender ACCOUNT2)
goal clerk sign -i groupedtransactions.tx -o signout.tx

# Send the group transaction to the network
goal clerk rawsend --filename signout.tx
```

Now let's view the global state of the smart contract. The counter should have been incremented to 1 since this transaction was for 10 ALGOs.

```bash
goal app read --global --app-id <APP_ID>
```

```bash
# Output
{
  "counter": {
    "tt": 2,
    "ui": 1    # Counter value is 1
  },
  "owner": {
    "tb": "\ufffd%b\ufffd\ufffd\n\ufffd\u001e\ufffdYMFȡ\ufffd\ufffd\ufffd\ufffd\u0004\ufffd\ufffd\ufffdc1\ufffd\ufffd\u0010\ufffd\u001a\ufffdP{",
    "tt": 1
  }
}
```

### Buggy Smart Contract Call

However, the smart contract is secretly buggy. Let's see if we can expose this bug. With the current global state, we will need to send two group transactions each with value less than 10 ALGOs to expose the bug.

This is the same code as above, just that the sending amount is 9 ALGOs instead of 10. Run this code twice. The first run should succeed just fine, but the second should fail.

```bash
# Create the unsigned transactions
goal clerk send --amount 9000000 --from <ACCOUNT2> --to <OWNER> --out ./unsginedtransaction1.tx    # Sends 9 ALGOs to OWNER
goal app call --app-id <APP_ID> --from <ACCOUNT2> --out ./unsginedtransaction2.tx

# Atomically group the transactions
cat unsginedtransaction1.tx unsginedtransaction2.tx > combinedtransactions.tx
goal clerk group -i combinedtransactions.tx -o groupedtransactions.tx

# Sign the group transaction (Can be signed as a whole since it is coming from the same sender ACCOUNT2)
goal clerk sign -i groupedtransactions.tx -o signout.tx

# Send the group transaction to the network
goal clerk rawsend --filename signout.tx
```

The second run should produce an error similar to this one:

```bash
Warning: Couldn't broadcast tx with algod: HTTP 400 Bad Request: TransactionPool.Remember: transaction <TXN-HASH>: logic eval error: - would result negative
Encountered errors in sending 2 transactions:
  <TXN-HASH>: HTTP 400 Bad Request: TransactionPool.Remember: transaction <TXN-HASH>: logic eval error: - would result negative
  <TXN-HASH>: HTTP 400 Bad Request: TransactionPool.Remember: transaction <TXN-HASH>: logic eval error: - would result negative
Cannot write file signout.tx.rej: open signout.tx.rej: file exists
```

There is some unhandled error in this smart contract relating to `"would result negative"`. Let's use the `tealdbg` debugger to better understand what is going wrong and fix this issue.

### Debugging the Smart Contract

In order to debug a smart contract, two sources are necessary:
1. The smart contract TEAL code (already have this)
2. The debugger context

The debugger context contains all of the necessary information (the transactions being issued, the global and local state, etc.) for the debugger to recreate the same enviroment where the smart contract failed.

Instead of sending the `signout.tx` from the second attempt which failed, we are going to dryrun it and save the debugger context.

```bash
# Generate the context debug file
goal clerk dryrun -t signout.tx --dryrun-dump -o dr.msgp
```

The `dr.msgp` file is the debugger context. Now we can launch `tealdbg` and begin debugging the buggy call to the smart contract.

```bash
# The smart contract transaction is at index 1 within the group
tealdbg debug approval_program.teal -d dr.msgp --group-index 1
```