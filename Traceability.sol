// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Traceability {

  address payable owner;
  mapping(string => string) public hashes;
  
    constructor() { 
      owner = payable(msg.sender); 
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function storeHash(string calldata traceId, string calldata hash) public onlyOwner {
      require(bytes(hashes[traceId]).length == 0,"the key already exists");
      hashes[traceId] = hash;
  }

}
