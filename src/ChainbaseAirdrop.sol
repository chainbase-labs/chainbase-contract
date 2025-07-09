// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./staking/IStaking.sol";

contract ChainbaseAirdrop is Ownable {
    using SafeERC20 for IERC20;

    //=========================================================================
    //                                CONSTANT
    //=========================================================================
    IERC20 public immutable cToken;

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    bool public isEnabled;
    bytes32 public merkleRoot;
    IStaking public stakingContract;
    mapping(address => bool) public claimed;

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event AirdropStateUpdated(bool isEnabled);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    event StakingContractUpdated(address indexed oldStakingContract, address indexed newStakingContract);
    event AirdropClaimed(address indexed user, uint256 amount);

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    constructor(address _cToken, bytes32 _merkleRoot) {
        require(_cToken != address(0), "ChainbaseAirdrop: Invalid cToken address");
        require(_merkleRoot != bytes32(0), "ChainbaseAirdrop: Invalid merkle root");
        cToken = IERC20(_cToken);
        merkleRoot = _merkleRoot;
    }

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    function setAirdropState(bool _isEnabled) external onlyOwner {
        isEnabled = _isEnabled;
        emit AirdropStateUpdated(_isEnabled);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        require(_newMerkleRoot != bytes32(0), "ChainbaseAirdrop: Invalid merkle root");
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(oldRoot, _newMerkleRoot);
    }

    function setStakingContract(address _newStakingContract) external onlyOwner {
        require(_newStakingContract != address(0), "ChainbaseAirdrop: Invalid staking contract address");
        address oldStakingContract = address(stakingContract);
        stakingContract = IStaking(_newStakingContract);
        emit StakingContractUpdated(oldStakingContract, _newStakingContract);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = cToken.balanceOf(address(this));
        cToken.safeTransfer(owner(), balance);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    function claimAirdrop(uint256 amount, bytes32[] calldata merkleProof, bool stake) external {
        require(isEnabled, "ChainbaseAirdrop: Airdrop is not enabled");
        require(address(stakingContract) != address(0), "ChainbaseAirdrop: Invalid staking contract address");
        require(!claimed[msg.sender], "ChainbaseAirdrop: Airdrop already claimed");
        require(cToken.balanceOf(address(this)) >= amount, "ChainbaseAirdrop: Insufficient balance");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "ChainbaseAirdrop: Invalid merkle proof");

        claimed[msg.sender] = true;

        if (stake) {
            cToken.safeTransfer(address(stakingContract), amount);
            stakingContract.delegateFromAirdrop(msg.sender, amount);
        } else {
            cToken.safeTransfer(msg.sender, amount);
        }

        emit AirdropClaimed(msg.sender, amount);
    }
}
