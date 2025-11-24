// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {PUSD_Deployer_Base} from "./base/PUSD_Deployer_Base.sol";

contract PUSD_Deployer is Script, PUSD_Deployer_Base {
    function run() external{
        uint256 cap_   = vm.envUint("PUSD_CAP");
        address admin_ = vm.envAddress("ADMIN");

        vm.startBroadcast();
        address tokenAddr = address(_deploy(cap_, admin_));
        vm.stopBroadcast();

        console.log("PUSD proxy addr:", tokenAddr);
    }
}
