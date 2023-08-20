// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/SafeProtocolManager.sol";
import {SafeProtocolRegistry} from "@safe-global/safe-core-protocol/contracts/SafeProtocolRegistry.sol";
import {Safe} from "@safe-contracts/contracts/Safe.sol";
import {Plugin} from "../../src/Plugin.sol";
import {SafeTxConfig} from "./SafeTxConfig.s.sol";
import {Enum} from "@safe-contracts/contracts/common/Enum.sol";


contract EnablePluginOnManager is Script {

    error EnablePluginFailure(bytes reason);

    function run(Safe safe, Plugin plugin , SafeProtocolManager manager) public {


        bytes32 safeTx;
    {safeTx = getTransactionHash(safe, address(manager), address(plugin));}
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x992d5389c6c8a8999ed6990df711fb4e16252bf11a054024a0a2529f0024b77c, safeTx);

          try safe.execTransaction(
            address(manager), //to
            0, //value
            abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false), //data
            Enum.Operation.Call, //operation
            250, //safeTxGas
            0, //baseGas
            0, //gasPrice
            address(0), //gasToken
            payable(address(0)), //refundReceiver
            abi.encodePacked(r, s, v) //sig
        ) returns (bool) {} catch (bytes memory reason) {
               revert EnablePluginFailure(reason);
    
        } 

        //vm.stopBroadcast();



    }

        function getTransactionHash(Safe safe, address manager, address plugin) public view returns (bytes32) {
            return safe.getTransactionHash(
            manager, 
            0,
            abi.encodeWithSignature("enablePlugin(address,bool)", plugin, false),
            Enum.Operation.Call,
            250,
            0,
            0,
            address(0), 
            payable(address(0)), 
            safe.nonce()
        );

    

}

}
