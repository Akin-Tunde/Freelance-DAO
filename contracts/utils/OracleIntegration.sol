// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleIntegration
 * @dev Provides a simple interface to get the latest price from a Chainlink Price Feed.
 * This decouples the core contracts from the specific oracle implementation.
 */
contract OracleIntegration {
    AggregatorV3Interface internal immutable priceFeed;

    // The price feed address is passed in the constructor, making this
    // contract reusable for any Chainlink feed (e.g., ETH/USD, MATIC/USD).
    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
     * @notice Returns the latest price from the Chainlink feed.
     * @return The price, which includes decimals (e.g., 8 for USD pairs).
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    /**
     * @notice Returns the number of decimals for the price feed.
     */
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}