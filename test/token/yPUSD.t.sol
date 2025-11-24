// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/token/yPUSD/yPUSD.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract yPUSDTest is Test {
    yPUSD public ypusd;
    yPUSD public implementation;
    ERC1967Proxy public proxy;

    address public admin = address(0x1);
    address public minter = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    event Minted(address indexed to, uint256 amount, address indexed minter);
    event Burned(address indexed from, uint256 amount, address indexed burner);
    event MinterRoleLocked(address indexed minter, address indexed admin);

    function setUp() public {
        vm.startPrank(admin);
        
        implementation = new yPUSD();
        
        bytes memory initData = abi.encodeWithSelector(
            yPUSD.initialize.selector,
            1_000_000e6, // Cap
            admin
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        ypusd = yPUSD(address(proxy));
        
        ypusd.grantRole(ypusd.MINTER_ROLE(), minter);
        
        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(ypusd.name(), "Yield Phoenix USD Token");
        assertEq(ypusd.symbol(), "yPUSD");
        assertEq(ypusd.decimals(), 6);
        assertEq(ypusd.cap(), 1_000_000e6);
        assertTrue(ypusd.hasRole(ypusd.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(ypusd.hasRole(ypusd.MINTER_ROLE(), minter));
        assertTrue(ypusd.minterRoleLocked());
    }

    function test_Mint() public {
        vm.startPrank(minter);
        
        uint256 amount = 1000e6;
        vm.expectEmit(true, false, true, true);
        emit Minted(user1, amount, minter);
        
        ypusd.mint(user1, amount);
        
        assertEq(ypusd.balanceOf(user1), amount);
        assertEq(ypusd.totalSupply(), amount);
        
        vm.stopPrank();
    }

    function test_Mint_RevertIfCapExceeded() public {
        vm.startPrank(minter);
        
        uint256 cap = ypusd.cap();
        ypusd.mint(user1, cap);
        
        vm.expectRevert("yPUSD: cap exceeded");
        ypusd.mint(user1, 1);
        
        vm.stopPrank();
    }

    function test_Mint_RevertIfNotMinter() public {
        vm.startPrank(user1);
        vm.expectRevert(); // AccessControl error
        ypusd.mint(user1, 100e6);
        vm.stopPrank();
    }

    function test_Burn() public {
        vm.startPrank(minter);
        ypusd.mint(user1, 1000e6);
        
        vm.expectEmit(true, false, true, true);
        emit Burned(user1, 500e6, minter);
        
        ypusd.burn(user1, 500e6);
        
        assertEq(ypusd.balanceOf(user1), 500e6);
        assertEq(ypusd.totalSupply(), 500e6);
        
        vm.stopPrank();
    }

    function test_Pause() public {
        vm.startPrank(admin);
        ypusd.pause();
        assertTrue(ypusd.paused());
        
        vm.stopPrank();
        
        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        ypusd.mint(user1, 100e6);
        vm.stopPrank();
        
        vm.startPrank(admin);
        ypusd.unpause();
        assertFalse(ypusd.paused());
        vm.stopPrank();
        
        vm.startPrank(minter);
        ypusd.mint(user1, 100e6);
        vm.stopPrank();
    }

    function test_MinterRoleLocked() public {
        // Minter role was granted in setUp, so it should be locked
        assertTrue(ypusd.minterRoleLocked());
        
        bytes32 minterRole = ypusd.MINTER_ROLE();

        vm.startPrank(admin);
        
        // Try to grant minter role again
        vm.expectRevert("yPUSD: MINTER_ROLE permanently locked");
        ypusd.grantRole(minterRole, user1);
        
        // Try to revoke minter role
        vm.expectRevert("yPUSD: Cannot revoke locked MINTER_ROLE");
        ypusd.revokeRole(minterRole, minter);
        
        vm.stopPrank();
        
        // Try to renounce
        vm.startPrank(minter);
        vm.expectRevert("yPUSD: Cannot renounce locked MINTER_ROLE");
        ypusd.renounceRole(minterRole, minter);
        vm.stopPrank();
    }

    function test_Upgrade() public {
        vm.startPrank(admin);
        
        yPUSD newImpl = new yPUSD();
        ypusd.upgradeToAndCall(address(newImpl), "");
        
        vm.stopPrank();
    }
}
