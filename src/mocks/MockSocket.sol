// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/ISocket.sol";
import "../interfaces/IPlug.sol";

contract MockSocket is ISocket {
    uint256 public immutable override _chainSlug;

    address public constant fastSwitchboard = address(1);
    address public constant optimisticSwitchboard = address(2);

    error WrongSiblingPlug();
    error WrongIntegrationType();

    struct PlugConfig {
        address siblingPlug;
        address inboundSwitchboard;
        address outboundSwitchboard;
    }

    // switchboard => siblingChainSlug => exists
    mapping(address => mapping(uint256 => bool)) public configExists;
    // plug => siblingChainSlug => config(inboundSwitchboard, outboundSwitchboard, siblingPlug)
    mapping(address => mapping(uint256 => PlugConfig)) public plugConfigs;

    error InvalidConnection();

    constructor(uint256 chainSlug_, uint256 siblingChainSlug_) {
        _chainSlug = chainSlug_;

        configExists[fastSwitchboard][siblingChainSlug_] = true;
        configExists[optimisticSwitchboard][siblingChainSlug_] = true;

        configExists[fastSwitchboard][chainSlug_] = true;
        configExists[optimisticSwitchboard][chainSlug_] = true;
    }

    function connect(
        uint256 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external override {
        if (
            !configExists[inboundSwitchboard_][siblingChainSlug_] ||
            !configExists[outboundSwitchboard_][siblingChainSlug_]
        ) revert InvalidConnection();

        PlugConfig storage plugConfig = plugConfigs[msg.sender][
            siblingChainSlug_
        ];

        plugConfig.siblingPlug = siblingPlug_;
        plugConfig.inboundSwitchboard = inboundSwitchboard_;
        plugConfig.outboundSwitchboard = outboundSwitchboard_;

        emit PlugConnected(
            msg.sender,
            siblingChainSlug_,
            siblingPlug_,
            inboundSwitchboard_,
            outboundSwitchboard_,
            address(0),
            address(0)
        );
    }

    function outbound(
        uint256 siblingChainSlug_,
        uint256 msgGasLimit_,
        bytes calldata payload_
    ) external payable override returns (uint256) {
        PlugConfig memory srcPlugConfig = plugConfigs[msg.sender][
            siblingChainSlug_
        ];

        PlugConfig memory dstPlugConfig = plugConfigs[
            srcPlugConfig.siblingPlug
        ][_chainSlug];

        if (dstPlugConfig.siblingPlug != msg.sender) revert WrongSiblingPlug();
        IPlug(srcPlugConfig.siblingPlug).inbound{gas: msgGasLimit_}(
            siblingChainSlug_,
            payload_
        );

        return 1;
    }

    function getPlugConfig(
        address plugAddress_,
        uint256 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        )
    {
        PlugConfig memory plugConfig = plugConfigs[plugAddress_][
            siblingChainSlug_
        ];
        return (
            plugConfig.siblingPlug,
            plugConfig.inboundSwitchboard,
            plugConfig.outboundSwitchboard,
            address(0),
            address(0)
        );
    }
}