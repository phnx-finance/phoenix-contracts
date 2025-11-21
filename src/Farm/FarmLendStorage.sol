// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../token/NFTManager/NFTManager.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPUSDOracle.sol";

contract FarmLendStorage {
    /// @notice Information about a loan backed by one NFT
    struct Loan {
        address borrower;
        uint256 remainingCollateralAmount; // in PUSD
        address debtToken; // USDT / USDC etc.
        uint256 borrowedAmount;
        bool active;
    }

    /// @notice NFT Manager contract which holds stake records
    NFTManager public nftManager;

    /// @notice Vault that actually holds liquidity and NFTs
    IVault public vault;

    /// @notice PUSD Oracle for price feeds
    IPUSDOracle public pusdOracle;

    /// @notice Allowed debt tokens (e.g. USDT/USDC)
    mapping(address => bool) public allowedDebtTokens;

    /// @notice Loan information by NFT tokenId
    mapping(uint256 => Loan) public loans;

    address public farm; // Farm contract address

    /// @notice Liquidation Collateral Ratio in basis points (e.g. 12500 = 125%)
    uint16 public liquidationRatio = 12500;

    /// @notice Target healthy Collateral Ratio in basis points (e.g. 13000 = 130%)
    uint16 public targetRatio = 13000;

    /// @notice Liquidation bonus in basis points (e.g. 300 = 3%)
    uint16 public liquidationBonus = 300; // 3% bonus to liquidators

    // PlaceHolder
    uint256[50] private __gap;

    // ---------- Events ----------
    event DebtTokenAllowed(address token, bool allowed);
    event VtlUpdated(uint16 oldVtlBps, uint16 newVtlBps);
    event Borrow(address indexed borrower, uint256 indexed tokenId, address indexed debtToken, uint256 amount);
    event Repay(address indexed borrower, uint256 indexed tokenId, address indexed debtToken, uint256 repaidAmount);
    event Liquidation(address indexed liquidator, uint256 indexed tokenId, address indexed debtToken, uint256 repaidAmount);
    event LiquidationRatioUpdated(uint16 oldValue, uint16 newValue);
    event TargetRatioUpdated(uint16 oldValue, uint16 newValue);
    event PUSDOracleUpdated(address oldOracle, address newOracle);
    event Liquidated(uint256 indexed tokenId, address indexed borrower, address liquidator, address indexed debtToken, uint256 repaidAmount, uint256 timestamp);
}
