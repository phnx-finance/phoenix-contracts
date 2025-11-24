// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {yPUSD} from "src/token/yPUSD/yPUSD.sol";
import {yPUSDStorage} from "src/token/yPUSD/yPUSDStorage.sol";
import {yPUSD_Deployer_Base} from "script/token/base/yPUSD_Deployer_Base.sol";
import {yPUSD_Upgrader_Base, yPUSDV2} from "script/token/base/yPUSD_Upgrader_Base.sol";

contract yPUSDTest is Test, yPUSD_Deployer_Base, yPUSD_Upgrader_Base {
    yPUSD token;
    yPUSDV2 tokenV2;

    address admin = address(0xA11CE);
    address user   = address(0xCAFE);

    uint256 constant CAP = 1_000_000_000 * 1e6;

    function setUp() public {
        token = _deploy(CAP, admin);
    }

    // ---------- Initialization related ----------

    function test_InitializeState() public {
        assertEq(token.name(), "Yield Phoenix USD Token");
        assertEq(token.symbol(), "yPUSD");
        assertEq(token.decimals(), 6);
        assertEq(token.cap(), CAP);
        
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
    }

    function test_InitializeOnlyOnce() public {
        vm.expectRevert();
        token.initialize(CAP,admin);
    }

    // ---------- Permission & Business Logic ----------

    function test_MinterCanMint() public {
        vm.prank(admin);
        token.mint(user, 100 * 1e6);
        assertEq(token.balanceOf(user), 100 * 1e6);
    }

    function test_NonMinterCannotMint() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100 * 1e6);
    }

    function test_MintRespectsCap() public {
        // First mint to close to cap
        vm.startPrank(admin);
        token.mint(user, CAP - 1);
        assertEq(token.totalSupply(), CAP - 1);

        // Then mint 2 should cap exceeded
        vm.expectRevert(bytes("yPUSD: cap exceeded"));
        token.mint(user, 2);

        vm.stopPrank();
    }

    function test_MinterCanBurn() public {
        vm.startPrank(admin);
        token.mint(user, 100 * 1e6);
        token.burn(user, 40 * 1e6);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 60 * 1e6);
    }

    // ---------- Pause Logic ----------

    function test_AdminCanPauseAndUnpause() public {
        vm.prank(admin);
        token.pause();
        assertTrue(token.paused());

        vm.prank(admin);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_MintWhenPausedReverts() public {
        vm.prank(admin);
        token.pause();

        vm.prank(admin);
        vm.expectRevert();
        token.mint(user, 1);
    }

    // ---------- Events ----------

    function test_MintEmitsMintedEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, false, true, true);
        emit yPUSDStorage.Minted(user, 100 * 1e6, admin);
        token.mint(user, 100 * 1e6);
    }

    // ---------- Upgrade ----------

    function test_UpgradeKeepsStateAndRoles() public {
        // 1. First mint some state on V1
        vm.prank(admin);
        token.mint(user, 123 * 1e6);
        assertEq(token.balanceOf(user), 123 * 1e6);
        assertEq(token.totalSupply(), 123 * 1e6);

        // 2. Upgrade to V2 (only admin has permission)
        yPUSDV2 implV2 = new yPUSDV2();

        vm.prank(admin);
        token.upgradeToAndCall(address(implV2), '');

        // 3. Use V2 ABI to operate the same proxy address
        tokenV2 = yPUSDV2(address(token));

        // 4. Previous state is preserved
        assertEq(tokenV2.balanceOf(user), 123 * 1e6);
        assertEq(tokenV2.totalSupply(), 123 * 1e6);
        assertEq(tokenV2.cap(), CAP);
        assertTrue(tokenV2.hasRole(tokenV2.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(tokenV2.hasRole(tokenV2.MINTER_ROLE(), admin));

        // 5. New logic works
        vm.prank(admin);
        tokenV2.setVersion(2);
        assertEq(tokenV2.version(), 2);
    }

    function test_UpgradeOnlyAdmin() public {
        yPUSDV2 implV2 = new yPUSDV2();

        // Non admin should be rejected by _authorizeUpgrade
        vm.prank(user);
        vm.expectRevert();
        token.upgradeToAndCall(address(implV2), '');
    }
}
