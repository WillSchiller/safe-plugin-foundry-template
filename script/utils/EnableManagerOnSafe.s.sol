// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Safe} from "@safe-contracts/contracts/Safe.sol";
import {SafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/SafeProtocolManager.sol";
import {SafeTxConfig} from "./SafeTxConfig.s.sol";

contract EnableManagerOnSafe is Script {
    error EnableModuleFailure(bytes reason);

    function run(Safe safe, SafeProtocolManager manager, SafeTxConfig.Config calldata config) public {
    
        bytes32 txHash = safe.getTransactionHash(
            address(safe),
            0,
            abi.encodeWithSignature("enableModule(address)", address(manager)),
            config.operation,
            config.safeTxGas,
            config.baseGas,
            config.gasPrice,
            address(0),
            payable(address(0)),
            safe.nonce()
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);

        try safe.execTransaction(
            address(safe), //to
            0, //value
            abi.encodeWithSignature("enableModule(address)", address(manager)), //data
            config.operation, //operation
            config.safeTxGas, //safeTxGas
            config.baseGas, //baseGas
            config.gasPrice, //gasPrice
            address(0), //gasToken
            payable(address(0)), //refundReceiver
            abi.encodePacked(r, s, v) //sig
        ) returns (bool) {} catch (bytes memory reason) {
            revert EnableModuleFailure(reason);
        }
    }
}
