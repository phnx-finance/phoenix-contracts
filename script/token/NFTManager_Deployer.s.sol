// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {NFTManager_Deployer_Base} from "./base/NFTManager_Deployer_Base.sol";

contract NFTManager_Deployer is Script, NFTManager_Deployer_Base {
    function run() external{
        string memory name_   = vm.envString("NAME");
        string memory symbol_ = vm.envString("SYMBOL");
        address admin_ = vm.envAddress("ADMIN");
        address farm_ = vm.envAddress("FARM");

        vm.startBroadcast();
        address nftManagerAddr = address(_deploy(name_, symbol_, admin_, farm_));
        vm.stopBroadcast();

        console.log("NFTManager proxy addr:", nftManagerAddr);
    }
}