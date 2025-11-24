// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {PUSD_Upgrader_Base} from "./base/PUSD_Upgrader_Base.sol";

contract PUSD_Upgrader is Script, PUSD_Upgrader_Base {
    function run() external {
        address proxyAddr = vm.envAddress("PUSD_PROXY");

        bytes memory initData = ""; // If you have reinitializer, you can encode it here

        vm.startBroadcast();
        address tokenV2Addr = address(_upgrade(proxyAddr, initData));
        vm.stopBroadcast();

        console.log("PUSD proxy addr:", proxyAddr);
        console.log("PUSDV2 proxy addr:", tokenV2Addr);
    }
}