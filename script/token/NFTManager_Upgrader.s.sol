// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {NFTManager_Upgrader_Base} from "./base/NFTManager_Upgrader_Base.sol";

contract NFTManager_Upgrader is Script, NFTManager_Upgrader_Base {
    function run() external {
        address proxyAddr = vm.envAddress("NFTMANAGER_PROXY");

        bytes memory initData = ""; // If you have reinitializer, you can encode it here

        vm.startBroadcast();
        address nftManagerV2Addr = address(_upgrade(proxyAddr, initData));
        vm.stopBroadcast();

        console.log("NFTManager proxy addr:", proxyAddr);
        console.log("NFTManagerV2 proxy addr:", nftManagerV2Addr);
    }
}