// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISocket} from "./interfaces/ISocket.sol";
import {IPlug} from "./interfaces/IPlug.sol";

contract Counter is IPlug {
    uint256 public number;
    address public owner;
    ISocket socket;

    constructor(address _socket) {
        owner = msg.sender;
        socket = ISocket(_socket);
    }

    //
    // Modifiers
    //
    modifier onlyOwner() {
        require(msg.sender==owner,"no auth");
        _;
    }
    modifier onlySocket() {
        require(msg.sender==address(socket),"no auth");
        _;
    }

    //
    // Set Socket Config
    //
    function setConfig(uint256 _remoteChainSlug, address _remotePlug) external {
        socket.setPlugConfig(_remoteChainSlug, _remotePlug, "FAST");
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function setNumber(uint256 newNumber, uint256 chainSlug) public payable {
        socket.outbound{value: msg.value}(chainSlug, 1000000, abi.encode(newNumber));
    }

    function inbound(bytes calldata payload_) external payable override{ 
        require(msg.sender==address(socket),"no auth");
        uint256 newNumber = abi.decode(payload_, (uint256));
        setNumber(newNumber);
    }

    function removeOwner() external onlyOwner() {
        owner = address(0);
    }
}
