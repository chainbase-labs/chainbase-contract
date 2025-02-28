// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
    mapping(address => bool) public claimed;

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event AirdropStateUpdated(bool isEnabled);
    event MerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    event AirdropClaimed(address indexed user, uint256 amount);

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    constructor(address _cToken, bytes32 _merkleRoot) {
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

    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(oldRoot, _newMerkleRoot);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = cToken.balanceOf(address(this));
        cToken.safeTransfer(owner(), balance);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    function claimAirdrop(uint256 amount, bytes32[] calldata merkleProof) external {
        require(isEnabled, "ChainbaseAirdrop: Airdrop is not enabled");
        require(!claimed[msg.sender], "ChainbaseAirdrop: Airdrop already claimed");
        require(cToken.balanceOf(address(this)) >= amount, "ChainbaseAirdrop: Insufficient balance");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "ChainbaseAirdrop: Invalid merkle proof");

        claimed[msg.sender] = true;
        cToken.safeTransfer(msg.sender, amount);

        emit AirdropClaimed(msg.sender, amount);
    }
}
