// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe/DataTypes.sol";

contract Plugin is BasePluginWithEventMetadata {

        constructor()
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "PluginName",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: ""
            })
        ){}

/**
 * @dev This contract is a plugin that can be used to interact with s Safe via the manager. 
 * You should write your plugin functions below. See this example for more help:
 * https://github.com/5afe/safe-core-protocol-demo/blob/main/contracts/contracts/Plugins.sol
 */
    
}
