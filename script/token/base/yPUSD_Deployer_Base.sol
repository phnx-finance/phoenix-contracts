// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {yPUSD} from "src/token/yPUSD/yPUSD.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract yPUSD_Deployer_Base {
    function _deploy(uint256 cap_, address admin_) internal returns (yPUSD token) {
        yPUSD impl = new yPUSD();

        bytes memory initData = abi.encodeCall(
            yPUSD.initialize,
            (
                cap_, 
                admin_
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        token = yPUSD(address(proxy));
    }
}
