//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Collection.sol";
import "./N2DRewards.sol";

// 특정 스마트 계약으로 보내고 받을 수 있는 인터페이스 활성화
contract NFTStaking is Ownable, IERC721Receiver {
    uint256 public totalStaked;

    // !struct to store a stake's token, owner, and earning values
    struct Stake {
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
    mapping(uint256 => Stake) public vault;

    constructor(Collection _nft, N2DRewards _token) {
        nft = _nft;
        token = _token;
    }

    function stake(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        totalStaked += tokenIds.length;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "[error] you'r not token");
            require(vault[tokenId].tokenId == 0 , "[error] already staked");
        }

        nft.transferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(msg.sender, tokenId, block.timestamp);

        vault[tokenId] = Stake({
            tokenId: uint24(tokenId),
            timestamp: uint48(block.timestamp),
            owner: msg.sender
        });
    }

    function unstakeMany(address account, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
        }
    }
    // ! NFT Staking Contract에 대한 CLAIM 기능 실행
    function claim(address account, uint256[] calldata tokenIds, bool unstake) internal {
        uint256 tokenId;
        uint256 earned =0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "Cannot claim");

            uint256 stakedAt = staked.timestamp;
            // ? timestamp-stakedAt => during Staking!  
            earned += 10000 ether * (block.timestamp - stakedAt) / 1 days;

            vault[tokenId] = Stake({
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp),
                owner: account
            });

            if (earned > 0) {
                earned /= 10000;
                token.mint(account, earned);
            } if (unstake) {
                unstakeMany(account, tokenIds);
            } 
            emit Claimed(account, earned);
        }
    }
  function earningInfo(uint256[] calldata tokenIds) external view returns (uint256[2] memory info) {
     uint256 tokenId;
     uint256 totalScore = 0;
     uint256 earned = 0;
      Stake memory staked = vault[tokenId];
      uint256 stakedAt = staked.timestamp;
      earned += 100000 ether * (block.timestamp - stakedAt) / 1 days;
    uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
    earnRatePerSecond = earnRatePerSecond / 100000;
    // earned, earnRatePerSecond
    return [earned, earnRatePerSecond];
  }

  // should never be used inside of transaction because of gas fee
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = nft.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    uint256 supply = nft.totalSupply();
    uint256[] memory tmp = new uint256[](supply);

    uint256 index = 0;
    for(uint tokenId = 1; tokenId <= supply; tokenId++) {
      if (vault[tokenId].owner == account) {
        tmp[index] = vault[tokenId].tokenId;
        index +=1;
      }
    }

    uint256[] memory tokens = new uint256[](index);
    for(uint i = 0; i < index; i++) {
      tokens[i] = tmp[i];
    }

    return tokens;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}
