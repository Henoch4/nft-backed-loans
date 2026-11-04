// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

interface IPawnNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract NFTBackedLoans is ReentrancyGuard, Ownable {
    struct Loan {
        address borrower;
        address lender;
        address nftContract;
        uint256 tokenId;
        uint256 principal;
        uint256 interestBps;
        uint256 durationSeconds;
        uint256 startTime;
        uint256 repayAmount;
        bool active;
        bool repaid;
        bool collateralLocked;
    }
    Loan[] public loans;
    mapping(address => uint256[]) public borrowerLoans;
    mapping(address => uint256[]) public lenderLoans;
    mapping(address => mapping(uint256 => uint256)) public nftToLoan;
    uint256 public loanCount;

    event LoanRequested(uint256 indexed lid, address indexed borrower, address nftContract, uint256 tokenId, uint256 principal);
    event LoanFunded(uint256 indexed lid, address indexed lender, uint256 amount);
    event LoanRepaid(uint256 indexed lid, address indexed borrower, uint256 amount);
    event LoanDefaulted(uint256 indexed lid, address indexed borrower, address nftContract, uint256 tokenId);

    function requestLoan(address nftContract, uint256 tokenId, uint256 principal, uint256 interestBps, uint256 durationSeconds)
        external nonReentrant returns (uint256) {
        require(principal > 0, "Zero principal");
        require(interestBps > 0, "Zero interest");
        require(durationSeconds > 0, "Zero duration");
        require(interestBps <= 10000, "Interest exceeds 100 percent");
        require(nftContract.code.length > 0, "Invalid NFT contract");
        require(nftToLoan[nftContract][tokenId] == 0, "Collateral already locked");
        require(IPawnNFT(nftContract).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        IPawnNFT(nftContract).transferFrom(msg.sender, address(this), tokenId);
        require(IPawnNFT(nftContract).ownerOf(tokenId) == address(this), "Collateral transfer failed");
        Loan storage l = loans.push();
        l.borrower = msg.sender;
        l.lender = address(0);
        l.nftContract = nftContract;
        l.tokenId = tokenId;
        l.principal = principal;
        l.interestBps = interestBps;
        l.durationSeconds = durationSeconds;
        l.startTime = 0;
        l.repayAmount = principal + (principal * interestBps / 10000);
        l.active = true;
        l.repaid = false;
        l.collateralLocked = true;
        uint256 lid = loans.length - 1;
        loanCount = lid + 1;
        borrowerLoans[msg.sender].push(lid);
        nftToLoan[nftContract][tokenId] = lid + 1;
        emit LoanRequested(lid, msg.sender, nftContract, tokenId, principal);
        return lid;
    }

    function fundLoan(uint256 lid) external payable nonReentrant {
        Loan storage l = loans[lid];
        require(l.lender == address(0), "Already funded");
        require(!l.repaid, "Already repaid");
        require(l.active && l.collateralLocked, "Loan inactive");
        require(msg.sender != l.borrower, "Cannot self fund");
        require(msg.value == l.principal, "Incorrect amount");
        l.lender = msg.sender;
        l.startTime = block.timestamp;
        lenderLoans[msg.sender].push(lid);
        (bool ok,) = l.borrower.call{value: l.principal}("");
        require(ok, "Principal transfer failed");
        emit LoanFunded(lid, msg.sender, msg.value);
    }

    function repayLoan(uint256 lid) external payable nonReentrant {
        Loan storage l = loans[lid];
        require(msg.sender == l.borrower, "Not borrower");
        require(!l.repaid, "Already repaid");
        require(l.lender != address(0), "Not funded");
        require(msg.value == l.repayAmount, "Incorrect repayment");
        nftToLoan[l.nftContract][l.tokenId] = 0;
        l.repaid = true;
        l.active = false;
        l.collateralLocked = false;
        IPawnNFT(l.nftContract).transferFrom(address(this), l.borrower, l.tokenId);
        (bool ok,) = l.lender.call{value: msg.value}("");
        require(ok, "Repayment transfer failed");
        emit LoanRepaid(lid, msg.sender, l.repayAmount);
    }

    function defaultLoan(uint256 lid) external nonReentrant {
        Loan storage l = loans[lid];
        require(!l.repaid, "Already repaid");
        require(l.lender != address(0), "Not funded");
        require(msg.sender == l.lender, "Not lender");
        require(block.timestamp >= l.startTime + l.durationSeconds, "Not yet due");
        l.repaid = true;
        l.active = false;
        l.collateralLocked = false;
        nftToLoan[l.nftContract][l.tokenId] = 0;
        IPawnNFT(l.nftContract).transferFrom(address(this), l.lender, l.tokenId);
        emit LoanDefaulted(lid, l.borrower, l.nftContract, l.tokenId);
    }

    function cancelLoan(uint256 lid) external nonReentrant {
        Loan storage l = loans[lid];
        require(msg.sender == l.borrower && l.lender == address(0), "Cannot cancel");
        require(l.active && !l.repaid, "Inactive loan");
        l.active = false; l.repaid = true; l.collateralLocked = false;
        nftToLoan[l.nftContract][l.tokenId] = 0;
        IPawnNFT(l.nftContract).transferFrom(address(this), l.borrower, l.tokenId);
    }

    function getLoan(uint256 lid) external view returns (address borrower, address lender, address nftContract, uint256 tokenId, uint256 principal, uint256 interestBps, uint256 duration, uint256 startTime, uint256 repayAmount, bool active, bool repaid, bool locked) {
        Loan storage l = loans[lid];
        return (l.borrower, l.lender, l.nftContract, l.tokenId, l.principal, l.interestBps, l.durationSeconds, l.startTime, l.repayAmount, l.active, l.repaid, l.collateralLocked);
    }
}
