# TokenBridgeRouter

You can find the code of this routing contract [here](./src/TokenBridgeRouter.sol).

This contract serves the purpose of a router for all the Teleporter bridges on a chain (see [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge)).

After deploying a bridge between an home chain and a remote one, you can register this bridge on the router. This way, if you have multiple bridges deployed on one chain, instead of searching for the correct bridge contract, you can just call the router with the token, the chain and the recipient and DONE!

To register a new bridge, you need first to deploy the bridge instance on both the home chain and the remote chain. When this is done, you have to deploy the router contract on both chain. Then you call the functions `registerHomeTokenBridge()` and `registerRemoteTokenBridge()`.

The `registerHomeTokenBridge()` takes a token address (A) and a bridge address (B) as parameters. With this, when you want to bridge the token (A) from this chain to a remote one, the router will know that it is the bridge (B) that needs to be use.

The `registerRemoteTokenBridge()` takes as parameters a token address (A), the ID of the remote chain (B), a bridge address (C), a required gas limit (D) and a boolean variable that indicates if the bridge needs a multihop (E). With this, when you want to bridge the token (A), the router will know which bridge (C) to use on which remote chain (B). The required gas limit (D) is needed to tell the router the limit of gas when bridging to this bridge instance on this remote chain. The boolean variable is used in the case of a bridge between two remote chains: in that case, the token (A) first needs to be bridged back to its home chain before being bridged to the desired remote chain (B).

Note that if you want to bridge a native token, you must call those registering functions with the address `0x0` as the token address.

After registering the bridge, you can call the bridge functions from the router: `bridgeERC20()` and `bridgeNative()`. The parameters of these functions are fewer and more concrete than those of the original `send()` functions from the bridge contracts.

For `bridgeERC20()`:

- the address of the token you want to bridge
- the ID of the chain you want to bridge to
- the amount of token you want to bridge
- the address of the recipient you want to send your tokens to
- a fallback address in case of a failed multihop bridge

For `bridgeNative()`:

- the ID of the chain you want to bridge to
- the address of the recipient you want to send your tokens to
- the address of the fee token
- a fallback address in case of a failed multihop bridge

Note that this function is `payable` meaning you will need to pass a `msg.value` when you call this function to indicate the amount to bridge.

## Test

```bash
forge test --mp "test/TokenBridgeRouter*" --via-ir
```
