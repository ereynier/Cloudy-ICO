# Cloudy ICO Smart Contract

This repository contains a Solidity smart contract for the Cloudy ICO, as well as the associated Cloudy token contract. The Cloudy ICO smart contract allows users to participate in a token sale event. It is built using Solidity, OpenZeppelin libraries, Chainlink price feeds, and custom libraries.

## Contract Overview

The Cloudy ICO contract facilitates the sale of tokens during a presale event. It interacts with the Cloudy token contract and allows users to purchase tokens using various ERC-20 tokens. The presale contract ensures that tokens are sold at a fixed price in USD and enforces certain rules to maintain the integrity of the sale.

## Features

- Purchase tokens using supported ERC-20 tokens before the presale is unlocked.
- Withdraw purchased tokens after the presale is unlocked.
- Burn remaining unsold tokens after the presale is unlocked.
- Withdraw all remaining tokens, including those of supported ERC-20 tokens.
- View contract and token information through various public and external functions.

## Technologies Used

- Solidity: A programming language for writing smart contracts on the Ethereum platform.
- Foundry: A development framework for building decentralized applications.
- OpenZeppelin Contracts: A library of reusable smart contracts for Ethereum.
- Chainlink Price Feeds: Used for obtaining accurate token prices in USD.

## Contract Addresses

- Cloudy ICO Contract: [0x5536B2802712ebFC248A895b31719A7b5e97378d](https://sepolia.etherscan.io/address/0x5536b2802712ebfc248a895b31719a7b5e97378d)
- Cloudy Token Contract: [0xDe72C023C9a56a1794Ef27adC213f09bD64BcE58](https://sepolia.etherscan.io/address/0xde72c023c9a56a1794ef27adc213f09bd64bce58)

## Usage

- Deploy the Cloudy ICO and Cloudy token contracts to your Ethereum network.
- Configure the presale parameters, including unlock timestamp, token price, maximum supply, and allowed tokens during contract deployment.
- Users can participate in the presale by calling the `buy` function with supported ERC-20 tokens.
- After the presale is unlocked, users can withdraw their purchased tokens using the `withdraw` function.
- Any remaining unsold tokens can be burned by calling the `burnRemaining` function.
- The owner can withdraw any ERC20 tokens used with the `withdrawAllTokens` function.
- View contract and token information using various public functions.

## Testing

To test the Cloudy ICO smart contract, you can use the Foundry framework. Below are the steps to run tests:

1. Install Foundry if you haven't already: [Foundry Documentation](https://book.getfoundry.sh/)
2. Clone this repository to your local environment.
3. Navigate to the project directory in your terminal.
4. Run the following command to execute the tests in a local environment:

   ```shell
   forge test
    ```

## License

This smart contract is licensed under the SPDX-License-Identifier specified in the contract file. Please review the license file for more details.

## Acknowledgements

- [Solidity Documentation](https://docs.soliditylang.org/)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://www.openzeppelin.com/)
- [Chainlink Documentation](https://docs.chain.link/docs)

## Contact

For any questions or inquiries, please contact me at [ereynier.42@gmail.com](mailto:ereynier.42@gmail.com).