// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
contract OracleIntegration {
    AggregatorV3Interface internal immutable priceFeed;
    constructor(address _priceFeedAddress) { priceFeed = AggregatorV3Interface(_priceFeedAddress); }
    function getLatestPrice() public view returns (int) { (, int price, , , ) = priceFeed.latestRoundData(); return price; }
    function getDecimals() public view returns (uint8) { return priceFeed.decimals(); }
}