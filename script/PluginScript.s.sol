// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {SafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/SafeProtocolManager.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {SafeProtocolRegistry} from "@safe-global/safe-core-protocol/contracts/SafeProtocolRegistry.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {Safe} from "@safe-contracts/contracts/Safe.sol";
import {Plugin} from "../src/Plugin.sol";
import {Enum} from "@safe-contracts/contracts/common/Enum.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
/**
 * @title Foundry Test Setup for Safe Plugin
 * @author Will Schiller
 * @notice Test Manager 0x4026BA244d773F17FFA2d3173dAFe3fdF94216b9
 *         Test Registry 0x9EFbBcAD12034BC310581B9837D545A951761F5A
 */

contract PluginScript is Script {
    using Strings for bytes;
    error EnableModuleFailure(bytes reason);

    Safe safe;
    Plugin plugin;
    SafeProtocolManager manager;
    SafeProtocolRegistry registry;
    Enum.Operation operation = Enum.Operation.Call;
    Enum.IntegrationType integrationType = Enum.IntegrationType.Plugin; // Move to another script. 

    uint256 safeTxGas = 250;
    uint256 gasPrice = 0;
    uint256 baseGas = 0;

    function run() public {
        vm.startBroadcast(vm.envUint("SAFE_OWNER_PRIVATE_KEY"));


        //dployments object
        plugin = new Plugin();
        manager = SafeProtocolManager(0x4026BA244d773F17FFA2d3173dAFe3fdF94216b9);
        registry = SafeProtocolRegistry(0xc9361a1c6A8DeB0e4bB069820BB3f0Eaf94ae829);
        safe = Safe(payable(vm.envAddress("SAFE_ADDRESS")));
        
        
        //TX object
        bytes memory data = abi.encodeWithSignature("enableModule(address)", address(manager));
        bytes32 safeTx = getTransactionHash(address(safe), data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), safeTx);
        //address signer = ecrecover(safeTx, v, r, s); for testing/debuggin
        bytes memory sig = abi.encodePacked(r, s, v); // Placeholder signature https://docs.safe.global/safe-core-protocol/signatures/eip-1271
        
        // Abstracted out to a function
        try safe.execTransaction(
            address(safe), //to
            0, //value
            data, //data
            operation, //operation
            safeTxGas, //safeTxGas
            baseGas, //baseGas
            gasPrice, //gasPrice
            address(0), //gasToken
            payable(address(0)), //refundReceiver
            sig //sig
        ) returns (bool) {} catch (bytes memory reason) {
               revert EnableModuleFailure(reason);
    
        }

        
        registry.addIntegration(address(plugin), integrationType);

    
 
        //(uint64 listedAt, uint64 flaggedAt) = SafeProtocolRegistry(registry).check(address(plugin));
    
        bytes memory data2 = abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false);
        bytes32 safeTx2 = getTransactionHash(address(manager), data2);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), safeTx2);
        bytes memory sig2 = abi.encodePacked(r2, s2, v2); // Placeholder signature https://docs.safe.global/safe-core-protocol/signatures/eip-1271
          try safe.execTransaction(
            address(manager), //to
            0, //value
            data2, //data
            operation, //operation
            safeTxGas, //safeTxGas
            baseGas, //baseGas
            gasPrice, //gasPrice
            address(0), //gasToken
            payable(address(0)), //refundReceiver
            sig2 //sig
        ) returns (bool) {} catch (bytes memory reason) {
               revert EnableModuleFailure(reason);
    
        } 

        vm.stopBroadcast();

    }

    function getTransactionHash(address _to, bytes memory _data) public view returns (bytes32) {
        return safe.getTransactionHash(
            _to, 0, _data, operation, safeTxGas, baseGas, gasPrice, address(0), payable(address(0)), safe.nonce()
        );
    }

}
