// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 10**10);
    }

    function getConversionRate(uint256 getAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPriceInUSD = getPrice();
        uint256 ethAmountInUSD = (ethPriceInUSD * getAmount) / 10**18;
        return ethAmountInUSD;
    }
}
