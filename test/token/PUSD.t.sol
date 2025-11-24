// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/token/PUSD/PUSD.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PUSDTest is Test {
    PUSD public pusd;
    PUSD public implementation;
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
        
        implementation = new PUSD();
        
        bytes memory initData = abi.encodeWithSelector(
            PUSD.initialize.selector,
            1_000_000e6, // Cap
            admin
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        pusd = PUSD(address(proxy));
        
        pusd.grantRole(pusd.MINTER_ROLE(), minter);
        
        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(pusd.name(), "Phoenix USD Token");
        assertEq(pusd.symbol(), "PUSD");
        assertEq(pusd.decimals(), 6);
        assertEq(pusd.cap(), 1_000_000e6);
        assertTrue(pusd.hasRole(pusd.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(pusd.hasRole(pusd.MINTER_ROLE(), minter));
        assertTrue(pusd.minterRoleLocked());
    }

    function test_Mint() public {
        vm.startPrank(minter);
        
        uint256 amount = 1000e6;
        vm.expectEmit(true, false, true, true);
        emit Minted(user1, amount, minter);
        
        pusd.mint(user1, amount);
        
        assertEq(pusd.balanceOf(user1), amount);
        assertEq(pusd.totalSupply(), amount);
        
        vm.stopPrank();
    }

    function test_Mint_RevertIfCapExceeded() public {
        vm.startPrank(minter);
        
        uint256 cap = pusd.cap();
        pusd.mint(user1, cap);
        
        vm.expectRevert("PUSD: cap exceeded");
        pusd.mint(user1, 1);
        
        vm.stopPrank();
    }

    function test_Mint_RevertIfNotMinter() public {
        vm.startPrank(user1);
        vm.expectRevert(); // AccessControl error
        pusd.mint(user1, 100e6);
        vm.stopPrank();
    }

    function test_Burn() public {
        vm.startPrank(minter);
        pusd.mint(user1, 1000e6);
        
        vm.expectEmit(true, false, true, true);
        emit Burned(user1, 500e6, minter);
        
        pusd.burn(user1, 500e6);
        
        assertEq(pusd.balanceOf(user1), 500e6);
        assertEq(pusd.totalSupply(), 500e6);
        
        vm.stopPrank();
    }

    function test_Pause() public {
        vm.startPrank(admin);
        pusd.pause();
        assertTrue(pusd.paused());
        
        vm.stopPrank();
        
        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        pusd.mint(user1, 100e6);
        vm.stopPrank();
        
        vm.startPrank(admin);
        pusd.unpause();
        assertFalse(pusd.paused());
        vm.stopPrank();
        
        vm.startPrank(minter);
        pusd.mint(user1, 100e6);
        vm.stopPrank();
    }

    function test_MinterRoleLocked() public {
        // Minter role was granted in setUp, so it should be locked
        assertTrue(pusd.minterRoleLocked());
        
        bytes32 minterRole = pusd.MINTER_ROLE();
        
        vm.startPrank(admin);
        
        // Try to grant minter role again
        vm.expectRevert("PUSD: MINTER_ROLE permanently locked");
        pusd.grantRole(minterRole, user1);
        
        // Try to revoke minter role
        vm.expectRevert("PUSD: Cannot revoke locked MINTER_ROLE");
        pusd.revokeRole(minterRole, minter);
        
        vm.stopPrank();
        
        // Try to renounce
        vm.startPrank(minter);
        vm.expectRevert("PUSD: Cannot renounce locked MINTER_ROLE");
        pusd.renounceRole(minterRole, minter);
        vm.stopPrank();
    }

    function test_Upgrade() public {
        vm.startPrank(admin);
        
        PUSD newImpl = new PUSD();
        pusd.upgradeToAndCall(address(newImpl), "");
        
        vm.stopPrank();
    }
}
