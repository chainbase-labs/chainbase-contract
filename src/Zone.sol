// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Zone is ERC721URIStorage, Ownable {
    //=========================================================================
    //                                STRUCTS
    //=========================================================================
    // Represents the current state of a manuscript submission
    enum ManuscriptStatus {
        None, // Initial state, manuscript doesn't exist
        Pending, // Manuscript submitted but not reviewed
        Approved, // Manuscript approved and NFT minted
        Rejected // Manuscript rejected by zone owner

    }

    // Stores all relevant information for a manuscript submission
    struct Manuscript {
        address developer; // Address of the manuscript submitter
        string metadataURI; // URI containing manuscript metadata
        ManuscriptStatus status; // Current status of the manuscript
    }

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    string public zoneMetadataURI; // Metadata URI for the entire Zone collection
    uint256 public nextTokenId; // Counter for the next token to be minted
    bool public transfersEnabled; // Flag to enable/disable NFT transfers
    // Maps manuscript hash to its details
    mapping(bytes32 => Manuscript) public manuscripts;
    // Maps token ID to its corresponding manuscript hash
    mapping(uint256 => bytes32) public tokenToManuscriptHash;
    // Maps manuscript hash to its minted token ID (if approved)
    mapping(bytes32 => uint256) public manuscriptHashToTokenId;

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event ManuscriptSubmitted(bytes32 indexed manuscriptHash, address indexed developer, string metadataURI);
    event ManuscriptApproved(bytes32 indexed manuscriptHash, uint256 indexed tokenId);
    event ManuscriptRejected(bytes32 indexed manuscriptHash);
    event ZoneMetadataUpdated(string metadataURI);
    event TransfersEnabled(bool enabled);

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    constructor(string memory zoneName, string memory zoneSymbol, string memory _zoneMetadataURI)
        ERC721(zoneName, zoneSymbol)
    {
        // token ID starts at 1
        nextTokenId = 1;
        transfersEnabled = false;
        zoneMetadataURI = _zoneMetadataURI;
        emit ZoneMetadataUpdated(_zoneMetadataURI);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    function setZoneMetadata(string memory _zoneMetadataURI) external onlyOwner {
        zoneMetadataURI = _zoneMetadataURI;
        emit ZoneMetadataUpdated(_zoneMetadataURI);
    }

    function setManuscriptMetadata(bytes32 manuscriptHash, string memory metadataURI) external {
        uint256 tokenId = manuscriptHashToTokenId[manuscriptHash];
        require(tokenId != 0, "Zone: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Zone: Not the owner of this NFT");
        _setTokenURI(tokenId, metadataURI);
    }

    function setTransfersEnabled(bool enabled) external onlyOwner {
        transfersEnabled = enabled;
        emit TransfersEnabled(enabled);
    }

    /**
     * @notice Submits a new manuscript for review
     * @param manuscriptHash Unique hash identifying the manuscript
     * @param metadataURI URI containing the manuscript's metadata
     */
    function submitManuscript(bytes32 manuscriptHash, string memory metadataURI) external {
        require(bytes(metadataURI).length > 0, "Zone: Empty metadataURI");
        require(manuscriptHash != bytes32(0), "Zone: Invalid manuscript hash");

        // Only allow submission if manuscript doesn't exist or was previously rejected
        require(
            manuscripts[manuscriptHash].status == ManuscriptStatus.None
                || manuscripts[manuscriptHash].status == ManuscriptStatus.Rejected,
            "Zone: Manuscript already exists or was approved"
        );

        manuscripts[manuscriptHash] =
            Manuscript({developer: msg.sender, metadataURI: metadataURI, status: ManuscriptStatus.Pending});

        emit ManuscriptSubmitted(manuscriptHash, msg.sender, metadataURI);
    }

    /**
     * @notice Batch approves or rejects pending manuscripts
     * @param manuscriptHashes Array of manuscript hashes to process
     * @param approvals Array of boolean values indicating approval status
     * @dev Only callable by contract owner
     */
    function approveManuscripts(bytes32[] calldata manuscriptHashes, bool[] calldata approvals) external onlyOwner {
        require(manuscriptHashes.length > 0, "Zone: Empty manuscriptHashes array");
        require(manuscriptHashes.length == approvals.length, "Zone: Arrays length mismatch");

        for (uint256 i = 0; i < manuscriptHashes.length; i++) {
            bytes32 manuscriptHash = manuscriptHashes[i];
            bool approved = approvals[i];

            Manuscript storage manuscript = manuscripts[manuscriptHash];

            require(manuscript.developer != address(0), "Zone: manuscript not found");
            require(manuscript.status == ManuscriptStatus.Pending, "Zone: manuscript not in pending status");

            if (!approved) {
                manuscript.status = ManuscriptStatus.Rejected;
                emit ManuscriptRejected(manuscriptHash);
                continue;
            }

            // Update manuscript status and create NFT for approved manuscripts
            manuscript.status = ManuscriptStatus.Approved;

            uint256 tokenId = nextTokenId;
            tokenToManuscriptHash[tokenId] = manuscriptHash;
            manuscriptHashToTokenId[manuscriptHash] = tokenId;

            // Mint NFT to the manuscript developer
            _safeMint(manuscript.developer, tokenId);
            _setTokenURI(tokenId, manuscript.metadataURI);
            nextTokenId++;

            emit ManuscriptApproved(manuscriptHash, tokenId);
        }
    }

    /**
     * @notice Returns the status of one or more manuscripts
     * @param manuscriptHashes Array of manuscript hashes to process
     */
    function getManuscriptStatuses(bytes32[] calldata manuscriptHashes)
        external
        view
        returns (ManuscriptStatus[] memory)
    {
        ManuscriptStatus[] memory statuses = new ManuscriptStatus[](manuscriptHashes.length);
        for (uint256 i = 0; i < manuscriptHashes.length; i++) {
            statuses[i] = manuscripts[manuscriptHashes[i]].status;
        }
        return statuses;
    }

    //=========================================================================
    //                                INTERNAL
    //=========================================================================
    /**
     * @notice Override of ERC721 transfer function to implement transfer restrictions
     * @dev Ensures transfers are only possible when transfersEnabled is true
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(transfersEnabled, "Zone: Transfers are currently disabled");
        super._transfer(from, to, tokenId);
    }
}
