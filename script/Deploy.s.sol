// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Deployer contract for Safe{Core} Protocol Plugin
 * @author @willschiller
 * @notice This contract deploys a plugin and registers it with the newly deployed Safe{Core} Protocol contracts.
 * @dev set the following environment variables in .env: 
 * safeAddress (The address of your safe), 
 * safeOwnerAddress (An EOA that is a owner of your dafe), 
 * safeOwnerPrivateKey (The EOA key) In production, you should not keep your private key in the env. 
 * @dev The script will deploy a plugin, register it with the protocol, and enable it for your safe.
 */

import "forge-std/Script.sol";
import {SafeProtocolManager} from "@safe/SafeProtocolManager.sol";
import {SafeProtocolRegistry} from "@safe/SafeProtocolRegistry.sol";
import {Safe} from "@safe/Safe.sol";
import {Plugin} from "../src/Plugin.sol";
import {DeployContracts} from "./utils/DeployContracts.s.sol";
import {SafeTxConfig} from "./utils/SafeTxConfig.s.sol";

contract Deploy is Script {
    error SafeTxFailure(bytes reason);

    Safe safe = Safe(payable(vm.envAddress("SAFE_ADDRESS")));
    address owner = vm.envAddress("SAFE_OWNER_ADDRESS");
    SafeTxConfig safeTxConfig = new SafeTxConfig();
    SafeTxConfig.Config config = safeTxConfig.run();
    DeployContracts contracts = new DeployContracts();

    function getTransactionHash(address _to, bytes memory _data) public view returns (bytes32) {
        return safe.getTransactionHash(
            _to,
            config.value,
            _data,
            config.operation,
            config.safeTxGas,
            config.baseGas,
            config.gasPrice,
            config.gasToken,
            config.refundReceiver,
            safe.nonce()
        );
    }

    function sendSafeTx(address _to, bytes memory _data, bytes memory sig) public {
        try safe.execTransaction(
            _to,
            config.value,
            _data,
            config.operation,
            config.safeTxGas,
            config.baseGas,
            config.gasPrice,
            config.gasToken,
            config.refundReceiver,
            sig //sig
        ){} catch (bytes memory reason) {
            revert SafeTxFailure(reason);
        }
    }

    function run() public {
        vm.startBroadcast(vm.envUint("SAFE_OWNER_PRIVATE_KEY"));
        
        (Plugin plugin, SafeProtocolManager manager, SafeProtocolRegistry registry) = contracts.run(owner);
        registry.addIntegration(address(plugin), config.integrationType);

        bytes32 txHash = getTransactionHash(address(safe), abi.encodeWithSignature("enableModule(address)", address(manager)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);
        sendSafeTx(address(safe), abi.encodeWithSignature("enableModule(address)", address(manager)), abi.encodePacked(r, s, v));

        txHash = getTransactionHash(address(manager), abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false));
        (v, r, s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);
        sendSafeTx(address(manager), abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false), abi.encodePacked(r, s, v));

        vm.stopBroadcast();
    }
}
