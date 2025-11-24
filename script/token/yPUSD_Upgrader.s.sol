// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {yPUSD_Upgrader_Base} from "./base/yPUSD_Upgrader_Base.sol";

contract yPUSD_Upgrader is Script, yPUSD_Upgrader_Base {
    function run() external {
        address proxyAddr = vm.envAddress("YPUSD_PROXY");

        bytes memory initData = ""; // If you have reinitializer, you can encode it here

        vm.startBroadcast();
        address tokenV2Addr = address(_upgrade(proxyAddr, initData));
        vm.stopBroadcast();

        console.log("yPUSD proxy addr:", proxyAddr);
        console.log("yPUSDV2 proxy addr:", tokenV2Addr);
    }
}
