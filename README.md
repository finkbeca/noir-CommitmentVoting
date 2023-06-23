# Private Voting using ZKPs 

Private Voting smart contract and circuits extending on [Noir's ZK Voting](https://github.com/noir-lang/noir-starter/tree/main/foundry-voting) to offer private voting that is not revealed to after the voting period is over. This does not only guarantee that the exact identity of the voters are not known from within the membership pool, but the actual votes are not disclosed to after the voting period has ended. Note that when votes are finally disclosed we still do not learn exactly who cast them.

## Testing: 
---
### Circuits

Within circuits/ run ```nargo test```

### Smart Contract

Install: ``` forge install```  

Build: ``` forge build ``` 

Test: ``` forge test ```
