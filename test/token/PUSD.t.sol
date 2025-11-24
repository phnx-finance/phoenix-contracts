// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {PUSD} from "src/token/PUSD/PUSD.sol";
import {PUSDStorage} from "src/token/PUSD/PUSDStorage.sol";
import {PUSD_Deployer_Base} from "script/token/base/PUSD_Deployer_Base.sol";
import {PUSD_Upgrader_Base, PUSDV2} from "script/token/base/PUSD_Upgrader_Base.sol";

contract PUSDTest is Test, PUSD_Deployer_Base, PUSD_Upgrader_Base {
    PUSD token;
    PUSDV2 tokenV2;

    address admin = address(0xA11CE);
    address user   = address(0xCAFE);

    uint256 constant CAP = 1_000_000_000 * 1e6;

    function setUp() public {
        token = _deploy(CAP, admin);
    }

    // ---------- Initialization related ----------

    function test_InitializeState() public {
        assertEq(token.name(), "Phoenix USD Token");
        assertEq(token.symbol(), "PUSD");
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
        vm.expectRevert(bytes("PUSD: cap exceeded"));
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

    // ---------- MINTER_ROLE Locking Logic ----------

    function test_GrantMinterRoleOnceAndLock() public {
        address newMinter = address(0xBEEF);

        assertFalse(token.hasRole(token.MINTER_ROLE(), newMinter));

        vm.prank(admin);
        // Adjust indexed check according to PUSDStorage event signature
        vm.expectEmit(true, true, false, false);
        emit PUSDStorage.MinterRoleLocked(newMinter, admin);
        token.grantRole(token.MINTER_ROLE(), newMinter);

        assertTrue(token.hasRole(token.MINTER_ROLE(), newMinter));

        // Again grant MINTER_ROLE (to any address) should fail because of locking
        vm.prank(admin);
        vm.expectRevert(bytes("PUSD: MINTER_ROLE permanently locked"));
        token.grantRole(token.MINTER_ROLE(), user);
    }

    function test_GrantMinterRoleToExistingMinterAlsoLocks() public {
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));

        vm.prank(admin);
        vm.expectRevert(bytes("PUSD: MINTER_ROLE permanently locked"));
        token.grantRole(token.MINTER_ROLE(), admin);
    }

    function test_CannotRevokeLockedMinterRole() public {
        address newMinter = address(0xBEEF);

        vm.prank(admin);
        vm.expectRevert(bytes("PUSD: Cannot revoke locked MINTER_ROLE"));
        token.revokeRole(token.MINTER_ROLE(), newMinter);
    }

    function test_CannotRenounceLockedMinterRole() public {
        vm.prank(admin);
        vm.expectRevert(bytes("PUSD: Cannot renounce locked MINTER_ROLE"));
        token.renounceRole(token.MINTER_ROLE(), admin);
    }

    function test_GrantAndRevokeOtherRoleStillWorks() public {
        bytes32 OTHER_ROLE = keccak256("OTHER_ROLE");
        address other = address(0xBEEF);

        // grant OTHER_ROLE
        vm.prank(admin);
        token.grantRole(OTHER_ROLE, other);
        assertTrue(token.hasRole(OTHER_ROLE, other));

        // revoke OTHER_ROLE
        vm.prank(admin);
        token.revokeRole(OTHER_ROLE, other);
        assertFalse(token.hasRole(OTHER_ROLE, other));
    }

    function test_RenounceOtherRoleStillWorks() public {
        bytes32 OTHER_ROLE = keccak256("OTHER_ROLE");

        // First grant, lock it
        vm.prank(admin);
        token.grantRole(OTHER_ROLE, admin);
        assertTrue(token.hasRole(OTHER_ROLE, admin));

        // Then renounce
        vm.prank(admin);
        token.renounceRole(OTHER_ROLE, admin);
        assertFalse(token.hasRole(OTHER_ROLE, admin));
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
        emit PUSDStorage.Minted(user, 100 * 1e6, admin);
        token.mint(user, 100 * 1e6);
    }

    function test_BurnEmitsBurnedEvent() public {
        vm.startPrank(admin);
        token.mint(user, 100 * 1e6);

        vm.expectEmit(true, false, true, true);
        emit PUSDStorage.Burned(user, 40 * 1e6, admin);
        token.burn(user, 40 * 1e6);
        vm.stopPrank();
    }

    function test_NonMinterCannotBurn() public {
        // First mint some state
        vm.prank(admin);
        token.mint(user, 100 * 1e6);

        // user has no MINTER_ROLE, directly calling burn should revert
        vm.prank(user);
        vm.expectRevert();
        token.burn(user, 10 * 1e6);
    }

    // ---------- Upgrade ----------

    function test_UpgradeKeepsStateAndRoles() public {
        // 1. First mint some state on V1
        vm.prank(admin);
        token.mint(user, 123 * 1e6);
        assertEq(token.balanceOf(user), 123 * 1e6);
        assertEq(token.totalSupply(), 123 * 1e6);

        // 2. Upgrade to V2 (only admin has permission)
        PUSDV2 implV2 = new PUSDV2();

        vm.prank(admin);
        token.upgradeToAndCall(address(implV2), '');

        // 3. Use V2 ABI to operate the same proxy address
        tokenV2 = PUSDV2(address(token));

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
        PUSDV2 implV2 = new PUSDV2();

        // Non admin should be rejected by _authorizeUpgrade
        vm.prank(user);
        vm.expectRevert();
        token.upgradeToAndCall(address(implV2), '');
    }
}
