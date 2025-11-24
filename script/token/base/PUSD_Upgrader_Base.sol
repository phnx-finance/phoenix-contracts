// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PUSD} from "src/token/PUSD/PUSD.sol";

// import {PUSDV2} from "../src/token/PUSD/PUSDV2.sol";
// New contract for upgrade or you can import from other file
contract PUSDV2 is PUSD {
    uint256 public version;

    function setVersion(uint256 v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        version = v;
    }
}

abstract contract PUSD_Upgrader_Base {
    // UUPS upgrade
    function _upgrade(address proxyAddr, bytes memory initData) internal returns (PUSDV2 tokenV2) {
        PUSDV2 implV2 = new PUSDV2();

        PUSD proxy = PUSD(proxyAddr); // old version

        proxy.upgradeToAndCall(address(implV2), initData);

        tokenV2 = PUSDV2(proxyAddr);
    }
}
