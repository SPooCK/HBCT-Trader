const HBCT_Trader = artifacts.require("HBCT_Trader");

module.exports = function (deployer) {
    // --- Main Net ---
    const tHBCT = "0x1233d5a0262c366393adcb9634146b6dad3cae29"; // HBCT Address
    const tTOKEN = "0xe9e7cea3dedca5984780bafc599bd69add087d56"; // BUSD Address
    const tUniswapV2Router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // PancakeSwap v2 Router

    // --- Test Net ---
    // const tHBCT = "0x071d88c83d6e79cb707da096a45f1cd9d1bd3c62"; // HBCT Address
    // const tTOKEN = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"; // BUSD Address
    // const tUniswapV2Router = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; // PancakeSwap Router

    deployer.deploy(HBCT_Trader, tHBCT, tTOKEN, tUniswapV2Router);
};