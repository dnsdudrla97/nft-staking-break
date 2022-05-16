//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Collection.sol";
import "./N2DRewards.sol";

// 특정 스마트 계약으로 보내고 받을 수 있는 인터페이스 활성화
contract NFTStaking is Ownable, IERC721Reciver {
    uint256 public totalStaked;

    // !struct to store a stake's token, owner, and earning values
    struct stake {
        uint24 tokenId; // nft tokenid
        uint48 timestamp; // timestamp를 캡처하고 timestamp가 발생하는 순간 블록 보상 계산을 시작해야 한다.
        address owner;  // nft owner
    }

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);   

    // NFT Collection, Rewards Token Smart Contract 
    Collection nft;
    N2DRewards token;


    // Vault 토큰에 대한 정보 (NFT TokenID, 발행한 시간, 소유자) 
    mapping(uint256, Stake) public vault;

    constructor(Collection _nft, N2DRewards _token) {
        nft = _nft;
        token = _token;
    }

    function stake()
}