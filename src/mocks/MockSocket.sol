// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface IPlug {
    /**
     * @notice executes the message received from source chain
     * @dev this should be only executable by socket
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        bytes calldata payload_
    ) external payable;
}

contract MockSocket {
    uint256 public immutable _chainSlug;

    error WrongRemotePlug();
    error WrongIntegrationType();

    struct PlugConfig {
        address remotePlug;
        bytes32 integrationType;
    }

    // integrationType => remoteChainSlug => address
    mapping(bytes32 => mapping(uint256 => bool)) public configExists;
    // plug => remoteChainSlug => config(verifiers, accums, deaccums, remotePlug)
    mapping(address => mapping(uint256 => PlugConfig)) public plugConfigs;

    error InvalidIntegrationType();

    constructor(uint256 chainSlug_, uint256 remoteChainSlug_) {
        _chainSlug = chainSlug_;

        bytes32 fastIntegration = keccak256(abi.encode("FAST"));
        bytes32 slowIntegration = keccak256(abi.encode("SLOW"));

        configExists[fastIntegration][remoteChainSlug_] = true;
        configExists[slowIntegration][remoteChainSlug_] = true;

        configExists[fastIntegration][chainSlug_] = true;
        configExists[slowIntegration][chainSlug_] = true;
    }

    function setPlugConfig(
        uint256 remoteChainSlug_,
        address remotePlug_,
        string memory integrationType_
    ) external {
        bytes32 integrationType = keccak256(abi.encode(integrationType_));
        if (!configExists[integrationType][remoteChainSlug_])
            revert InvalidIntegrationType();

        PlugConfig storage plugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        plugConfig.remotePlug = remotePlug_;
        plugConfig.integrationType = integrationType;
    }

    function getPlugConfig(
        uint256 remoteChainSlug_,
        address plug_
    )
        external
        view
        returns (
            address accum,
            address deaccum,
            address verifier,
            address remotePlug,
            bytes32 integrationType
        )
    {
        PlugConfig memory plugConfig = plugConfigs[plug_][remoteChainSlug_];
        return (
            address(0),
            address(0),
            address(0),
            plugConfig.remotePlug,
            plugConfig.integrationType
        );
    }

    function outbound(
        uint256 remoteChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable {
        PlugConfig memory srcPlugConfig = plugConfigs[msg.sender][
            remoteChainSlug_
        ];

        PlugConfig memory dstPlugConfig = plugConfigs[srcPlugConfig.remotePlug][
            _chainSlug
        ];

        if (dstPlugConfig.remotePlug != msg.sender) revert WrongRemotePlug();
        if (dstPlugConfig.integrationType != srcPlugConfig.integrationType)
            revert WrongIntegrationType();
        IPlug(srcPlugConfig.remotePlug).inbound{gas: msgGasLimit_}(
            payload_
        );
    }
}