// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
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

contract PluginTest is Test {
    using Strings for bytes;
    error EnableModuleFailure(bytes reason);

    Safe safe;
    Plugin plugin;
    SafeProtocolManager manager;
    SafeProtocolRegistry registry;
    Enum.Operation operation = Enum.Operation.Call;
    Enum.IntegrationType integrationType = Enum.IntegrationType.Plugin; 

    uint256 safeTxGas = 1000000000000000000;
    uint256 gasPrice = 1;
    uint256 baseGas = 0;
    address pluginAddress;

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("GOERLI_RPC_URL")));
        vm.startPrank(vm.envAddress("SAFE_OWNER_ADDRESS"));
        vm.deal(vm.envAddress("SAFE_OWNER_ADDRESS"),10000 ether);
        //vm.deal(vm.envAddress("SAFE_ADDRESS"),10000 ether);
        console.logUint(vm.envAddress("SAFE_ADDRESS").balance);
        
        plugin = new Plugin();
        pluginAddress = address(plugin);
        bool x = plugin.requiresRootAccess();
        manager = SafeProtocolManager(0x4026BA244d773F17FFA2d3173dAFe3fdF94216b9);
        registry = SafeProtocolRegistry(0xc9361a1c6A8DeB0e4bB069820BB3f0Eaf94ae829);
        safe = Safe(payable(vm.envAddress("SAFE_ADDRESS")));
        bytes memory data = abi.encodeWithSignature("enableModule(address)", address(manager));
        bytes32 safeTx = getTransactionHash(address(safe), data);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), safeTx);
        //address signer = ecrecover(safeTx, v, r, s); for testing/debuggin
        bytes memory sig = abi.encodePacked(r, s, v); // Placeholder signature https://docs.safe.global/safe-core-protocol/signatures/eip-1271
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
        //vm.roll(block.number + 100);
        (uint64 listedAt, uint64 flaggedAt) = SafeProtocolRegistry(registry).check(address(plugin));
        console.log("listedAt: %s", listedAt);
        console.log("flaggedAt: %s", flaggedAt);
        
        bytes memory data2 = abi.encodeWithSignature("enablePlugin(address,bool)", pluginAddress, false);
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

    } 

    function getTransactionHash(address _to, bytes memory _data) public returns (bytes32) {
        return safe.getTransactionHash(
            _to, 0, _data, operation, safeTxGas, baseGas, gasPrice, address(0), address(0), safe.nonce()
        );
    }

    function testNonce() public {
        uint256 nonce = safe.nonce();
    }

    function testisPluginEnabled() public {


        bool enabled = manager.isPluginEnabled(vm.envAddress("SAFE_ADDRESS"),pluginAddress);
        assertEq(enabled, true);
        /**
         *  SafeProtocolAction[] memory actions = new SafeProtocolAction[](2);
         *         actions[0].to = payable(address(manager));
         *         actions[0].value = 0;
         *         actions[0].data = abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false);
         */
    }
}
