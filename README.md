# **Supra Automation Module**
This automation module creates an autonomous wallet top-up system.

## **How It Works:**

- **Monitors**: Target wallet `0x...` which can be setup via CLI During Automation Registry.
- **Threshold**: 600 SUPRA tokens
- **Top-up amount**: 50 SUPRA per execution
- **Checks every block** If target balance < 600 SUPRA?
- **If YES** then automatically transfers 50 SUPRA from deployer to target address.
- **If NO** then does nothing, waits for next block
- `init_module` creates module state when deployed.
- Entry functions depend on that state to work.

## **Use Cases:**
- **Wallet maintenance**: Keep wallets funded automatically
- **Gas fee protection**: Ensure accounts never run out of tokens
- **Treasury management**: Maintain minimum balances across multiple wallets
- **DeFi strategies**: Auto-fund trading or staking accounts
