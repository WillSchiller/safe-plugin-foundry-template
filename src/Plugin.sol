// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";

contract Plugin is BasePluginWithEventMetadata {

    error Err();

        constructor()
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "PluginXL2",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""
            })
        ){}

    
}
