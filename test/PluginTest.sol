// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {SafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/SafeProtocolManager.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {SafeProtocolRegistry} from "@safe-global/safe-core-protocol/contracts/SafeProtocolRegistry.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {Safe} from "@safe-contracts/contracts/Safe.sol";
import {SafeProxy} from "@safe-contracts/contracts/proxies/SafeProxy.sol";
import {TokenCallbackHandler} from "@safe-contracts/contracts/handler/TokenCallbackHandler.sol";
import {Plugin} from "../src/Plugin.sol";
import {Enum} from "@safe-contracts/contracts/common/Enum.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {SafeTxConfig} from "../script/utils/SafeTxConfig.s.sol";
/**
 * @title Foundry Test Setup for Safe Plugin
 * @author Will Schiller
 */

contract PluginTest is Test {
    error SafeTxFailure(bytes reason);
    address owner = vm.envAddress("SAFE_OWNER_ADDRESS");
    Safe singleton;
    SafeProxy proxy;
    Safe safe;
    TokenCallbackHandler handler;
    Plugin plugin;
    SafeProtocolManager manager;
    SafeProtocolRegistry registry;
    SafeTxConfig safeTxConfig = new SafeTxConfig();
    SafeTxConfig.Config config = safeTxConfig.run();

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

    function setUp() public {
        vm.startPrank(owner);
        vm.selectFork(vm.createFork(vm.envString("GOERLI_RPC_URL")));
        plugin = new Plugin();
        registry = new SafeProtocolRegistry(owner);
        manager = new SafeProtocolManager(owner, address(registry));
        singleton = new Safe();
        proxy = new SafeProxy(address(singleton));
        handler = new TokenCallbackHandler();
        safe = Safe(payable(address(proxy)));
        address[] memory owners = new address[](1);
        owners[0] = owner;
        safe.setup(owners, 1, address(0), bytes(""), address(handler), address(0), 0, payable(address(owner)));
        registry.addIntegration(address(plugin), Enum.IntegrationType.Plugin);

        bytes32 txHash = getTransactionHash(address(safe), abi.encodeWithSignature("enableModule(address)", address(manager)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);
        sendSafeTx(address(safe), abi.encodeWithSignature("enableModule(address)", address(manager)), abi.encodePacked(r, s, v));

        txHash = getTransactionHash(address(manager), abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false));
        (v, r, s) = vm.sign(vm.envUint("SAFE_OWNER_PRIVATE_KEY"), txHash);
        sendSafeTx(address(manager), abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false), abi.encodePacked(r, s, v));

    }

    function testisPluginEnabled() public {
        bool enabled = manager.isPluginEnabled(address(safe),address(plugin));
        assertEq(enabled, true);
        /**
         *  SafeProtocolAction[] memory actions = new SafeProtocolAction[](2);
         *         actions[0].to = payable(address(manager));
         *         actions[0].value = 0;
         *         actions[0].data = abi.encodeWithSignature("enablePlugin(address,bool)", address(plugin), false);
         */
    }
}
