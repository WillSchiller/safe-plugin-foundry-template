// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Enum} from "@safe/common/Enum.sol";

contract SafeTxConfig is Script {
    struct Config {
        Enum.Operation operation;
        Enum.IntegrationType integrationType;
        uint256 value;
        uint256 safeTxGas;
        uint256 gasPrice;
        uint256 baseGas;
        address gasToken;
        address payable refundReceiver;
    }

    function run() public view returns (Config memory) {
        Config memory config = Config({
            operation: Enum.Operation.Call,
            integrationType: Enum.IntegrationType.Plugin,
            value: 0,
            safeTxGas: 250,
            gasPrice: 0,
            baseGas: 0,
            gasToken: address(0), 
            refundReceiver: payable(vm.envAddress("SAFE_OWNER_ADDRESS"))
        });
        return config;
    }
}
