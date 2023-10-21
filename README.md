# Liquidity Position Conduit

### **Leveraged Uniswap v4 Liquidity Positions with Maker Conduits**

Maker Conduits through Endgame and subDAOs enable systems that benefit from DAI liquidity. With a specially tailored [Conduit](src/LPConduit.sol), allocated DAI can be paired with user tokens to enable leveraged LPs.

Example:

1. A subDAO allocates `$DAI`` to the LPConduit
3. Alice creates a concentrated liquidity position (DAI/USDC) on Uniswap v4, by providing `$USDC`
4. Swap fee revenue from the LP can then be shared between Maker and Alice
5. The subDAO/Conduit owns the LP and can unwind the position to reclaim the allocated $DAI

---

Relevant contracts:
```
liquidity-position-conduit
├── src
│   ├── LPConduit.sol      // Conduit contract that accepts $DAI allocation
│   └── ProvisionerV4.sol  // Conduit inherits ProvisionerV4, handles Uniswap v4 LPing
└── test
    ├── LPConduit.t.sol    // Example scenarios of leveraged (and de-leveraged) LPs
├── lib
│   ├── bungi
│   │   ├── src
│   │   │   ├── LiquidityPositionManager.sol  // Experimental Uniswap v4 Liquidity Position Manager
```

---

## Examples Usage

DAI allocation and LP Creation
```solidity
// supply DAI to the conduit
DAI.approve(address(conduit), 10_000e18);
conduit.deposit(allocDAO, address(DAI), 10_000e18);


// Define the LP range
Position memory position = Position({poolKey: poolKey, tickLower: -600, tickUpper: 600});

// Calculate the liquidity amount based on:
//   1. the current price of the pool
//   2. the lower range of the LP
//   3. the upper range of the LP
//   4. the amount of DAI allocated to the conduit
//   5. the amount of token1 (USDC) that Alice wants to provide
(, int24 currentTick,,) = manager.getSlot0(poolId);
uint256 liq = LiquidityAmounts.getLiquidityForAmounts(
    TickMath.getSqrtRatioAtTick(currentTick),
    TickMath.getSqrtRatioAtTick(position.tickLower),
    TickMath.getSqrtRatioAtTick(position.tickUpper),
    DAI.balanceOf(address(conduit)),
    token1.balanceOf(address(alice))
);

// Create the LP!
conduit.createPosition(position, token1.balanceOf(address(alice)), uint256(liq), ZERO_BYTES);
```


Reclaim DAI by closing LPs
```solidity
// ... assume the LP has been created
Position memory position = Position({poolKey: poolKey, tickLower: -600, tickUpper: 600});

// subDAO force-closes positions to reclaim DAI
conduit.closeAll(position, ZERO_BYTES);

conduit.withdraw(allocDAO, address(DAI), DAI_AMOUNT);
```
