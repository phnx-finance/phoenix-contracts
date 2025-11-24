// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PUSD} from "src/token/PUSD/PUSD.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract PUSD_Deployer_Base {
    function _deploy(uint256 cap_, address admin_) internal returns (PUSD token) {
        PUSD impl = new PUSD();

        bytes memory initData = abi.encodeCall(
            PUSD.initialize,
            (
                cap_, 
                admin_
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        token = PUSD(address(proxy));
    }
}
