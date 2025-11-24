// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/token/NFTManager/NFTManager.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTManagerTest is Test {
    NFTManager public nftManager;
    NFTManager public implementation;
    ERC1967Proxy public proxy;

    address public admin = address(0x1);
    address public farm = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    event StakeNFTMinted(uint256 indexed tokenId, address indexed to, uint256 amount, uint256 startTime, uint256 lockPeriod, uint16 rewardMultiplier, uint256 pendingReward);
    event StakeRecordUpdated(uint256 indexed tokenId, uint256 amount, uint256 lastClaimTime, uint16 rewardMultiplier, bool active, uint256 pendingReward);

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy implementation
        implementation = new NFTManager();
        
        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            NFTManager.initialize.selector,
            "Phoenix Stake",
            "PHNX-STK",
            admin,
            farm
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        nftManager = NFTManager(address(proxy));
        
        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(nftManager.name(), "Phoenix Stake");
        assertEq(nftManager.symbol(), "PHNX-STK");
        assertEq(nftManager.owner(), admin);
        assertTrue(nftManager.hasRole(nftManager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(nftManager.hasRole(nftManager.MINTER_ROLE(), farm));
        assertTrue(nftManager.hasRole(nftManager.METADATA_EDITOR_ROLE(), farm));
    }

    function test_MintStakeNFT() public {
        vm.startPrank(farm);
        
        uint256 amount = 1000e18;
        uint64 lockPeriod = 30 days;
        uint16 multiplier = 100;
        uint256 pendingReward = 0;

        vm.expectEmit(true, true, false, true);
        emit StakeNFTMinted(1, user1, amount, uint256(block.timestamp), uint256(lockPeriod), multiplier, pendingReward);
        
        uint256 tokenId = nftManager.mintStakeNFT(user1, amount, lockPeriod, multiplier, pendingReward);
        
        assertEq(tokenId, 1);
        assertEq(nftManager.ownerOf(1), user1);
        
        IFarm.StakeRecord memory record = nftManager.getStakeRecord(1);
        assertEq(record.amount, amount);
        assertEq(record.lockPeriod, lockPeriod);
        assertEq(record.rewardMultiplier, multiplier);
        assertTrue(record.active);
        
        vm.stopPrank();
    }

    function test_MintStakeNFT_RevertIfNotMinter() public {
        vm.startPrank(user1);
        vm.expectRevert("NFTManager: not authorized to mint");
        nftManager.mintStakeNFT(user1, 100, 0, 0, 0);
        vm.stopPrank();
    }

    function test_UpdateStakeRecord() public {
        // First mint a token
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(farm); // Farm has METADATA_EDITOR_ROLE
        
        uint256 newAmount = 2000e18;
        uint64 newLastClaimTime = uint64(block.timestamp + 1 days);
        uint16 newMultiplier = 200;
        bool newActive = false;
        uint256 newPendingReward = 50e18;

        vm.expectEmit(true, false, false, true);
        emit StakeRecordUpdated(tokenId, newAmount, uint256(newLastClaimTime), newMultiplier, newActive, newPendingReward);

        nftManager.updateStakeRecord(tokenId, newAmount, newLastClaimTime, newMultiplier, newActive, newPendingReward);
        
        IFarm.StakeRecord memory record = nftManager.getStakeRecord(tokenId);
        assertEq(record.amount, newAmount);
        assertEq(record.lastClaimTime, newLastClaimTime);
        assertEq(record.rewardMultiplier, newMultiplier);
        assertEq(record.active, newActive);
        assertEq(record.pendingReward, newPendingReward);
        
        vm.stopPrank();
    }

    function test_UpdateStakeRecord_RevertIfNotEditor() public {
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(user1);
        vm.expectRevert("NFTManager: not authorized to edit metadata");
        nftManager.updateStakeRecord(tokenId, 2000e18, 0, 0, false, 0);
        vm.stopPrank();
    }

    function test_UpdateRewardInfo() public {
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(farm);
        
        uint256 newPendingReward = 100e18;
        uint64 newLastClaimTime = uint64(block.timestamp + 2 days);

        nftManager.updateRewardInfo(tokenId, newPendingReward, newLastClaimTime);
        
        IFarm.StakeRecord memory record = nftManager.getStakeRecord(tokenId);
        assertEq(record.pendingReward, newPendingReward);
        assertEq(record.lastClaimTime, newLastClaimTime);
        // Ensure other fields didn't change
        assertEq(record.amount, 1000e18);
        
        vm.stopPrank();
    }

    function test_UpdateStakeRecord_Struct() public {
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(farm);
        
        IFarm.StakeRecord memory newRecord = IFarm.StakeRecord({
            amount: 5000e18,
            startTime: 100,
            lockPeriod: 60 days,
            lastClaimTime: 200,
            rewardMultiplier: 300,
            active: false,
            pendingReward: 1000e18
        });

        nftManager.updateStakeRecord(tokenId, newRecord);
        
        IFarm.StakeRecord memory record = nftManager.getStakeRecord(tokenId);
        assertEq(record.amount, newRecord.amount);
        assertEq(record.startTime, newRecord.startTime);
        assertEq(record.lockPeriod, newRecord.lockPeriod);
        assertEq(record.lastClaimTime, newRecord.lastClaimTime);
        assertEq(record.rewardMultiplier, newRecord.rewardMultiplier);
        assertEq(record.active, newRecord.active);
        assertEq(record.pendingReward, newRecord.pendingReward);
        
        vm.stopPrank();
    }
    
    function test_UpdateStakeRecord_Struct_RevertIfNotFarm() public {
         vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(admin); // Admin is owner but not farm address
        
        IFarm.StakeRecord memory newRecord = IFarm.StakeRecord({
            amount: 5000e18,
            startTime: 100,
            lockPeriod: 60 days,
            lastClaimTime: 200,
            rewardMultiplier: 300,
            active: false,
            pendingReward: 1000e18
        });

        vm.expectRevert("NFTManager: only farm can call");
        nftManager.updateStakeRecord(tokenId, newRecord);
        vm.stopPrank();
    }

    function test_Burn() public {
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        // User1 must approve farm to burn (since burn calls super.burn which checks approval)
        vm.prank(user1);
        nftManager.approve(farm, tokenId);

        vm.startPrank(farm); 
        
        nftManager.burn(tokenId);
        
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", tokenId));
        nftManager.ownerOf(tokenId);
        
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", tokenId));
        nftManager.getStakeRecord(tokenId);
        
        vm.stopPrank();
    }

    function test_TokenURI() public {
        vm.prank(farm);
        uint256 tokenId = nftManager.mintStakeNFT(user1, 1000e18, 30 days, 100, 0);

        vm.startPrank(admin);
        nftManager.setBaseURI("https://api.phoenix.com/metadata/");
        vm.stopPrank();

        assertEq(nftManager.tokenURI(tokenId), "https://api.phoenix.com/metadata/1");

        vm.startPrank(farm);
        nftManager.setTokenURI(tokenId, "custom_uri");
        vm.stopPrank();

        assertEq(nftManager.tokenURI(tokenId), "https://api.phoenix.com/metadata/custom_uri");
    }

    function test_Upgrade() public {
        vm.startPrank(admin);
        
        NFTManager newImpl = new NFTManager();
        nftManager.upgradeToAndCall(address(newImpl), "");
        
        vm.stopPrank();
    }
    
    function test_Upgrade_RevertIfNotAdmin() public {
        vm.startPrank(user1);
        
        NFTManager newImpl = new NFTManager();
        vm.expectRevert(); // AccessControl error
        nftManager.upgradeToAndCall(address(newImpl), "");
        
        vm.stopPrank();
    }
}
