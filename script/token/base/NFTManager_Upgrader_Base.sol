// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NFTManager} from "src/token/NFTManager/NFTManager.sol";

// import {NFTManagerV2} from "";
// New contract for upgrade or you can import from other file
contract NFTManagerV2 is NFTManager {
    uint256 public version;

    function setVersion(uint256 v) external onlyAdmin {
        version = v;
    }
}

abstract contract NFTManager_Upgrader_Base {
    function _upgrade(address proxyAddr, bytes memory initData) internal returns (NFTManagerV2 managerV2) {
        NFTManagerV2 implV2 = new NFTManagerV2();

        NFTManager proxy = NFTManager(proxyAddr);

        proxy.upgradeToAndCall(address(implV2), initData);

        managerV2 = NFTManagerV2(proxyAddr);
    }
}
