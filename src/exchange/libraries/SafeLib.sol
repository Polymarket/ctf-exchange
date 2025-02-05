// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import {ISafe} from "exchange/interfaces/ISafe.sol";


/// @title SafeLib
/// @notice Helper library to compute Limitless Safe 4337 addresses
library SafeLib {
    address public constant ZERO_ADDRESS = address(0);

    /// @notice Hardcoded addresses for Safe-related contracts used in Limitless Safe 4337.
    /// @dev These addresses are fixed because we rely on a specific set of Safe versions:
    ///      - Safe 4337 Module: v0.2.0
    ///      - Safe Proxy Factory: v1.4.1
    ///      - Add Modules Library: v1.3.0
    ///      - Safe Singleton: v1.4.1
    ///      - Multi Send: v1.4.1
    ///
    ///      If future implementations require different versions, we will extend the signature type
    ///      and introduce a new type with updated implementations.
    ///
    ///      Due to this strict version dependency and our approach of adding new signature types
    ///      as needed, we intentionally avoid maintaining getters and setters for these addresses.
    ///      Since they are not expected to change, additional management functions would be redundant.
    address public constant addModuleLibAddress =       0x8EcD4ec46D4D2a6B64fE960B3D64e8B94B2234eb;
    address public constant safe4337ModuleAddress =     0xa581c4A4DB7175302464fF3C06380BC3270b4037;
    address public constant safeProxyFactoryAddress =   0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67;
    address public constant safeSingletonAddress =      0x41675C099F32341bf84BFc5382aF534df5C7461a;
    address public constant multiSendAddress =          0x38869bf66a61cF6bDB996A6aE40D5853Fd43B526;

    struct InternalTx {
        address to;
        bytes data;
        uint256 value;
        uint8 operation;
    }

    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b506040516101e63803806101e68339818101604052602081101561003357600080fd5b8101908080519060200190929190505050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1614156100ca576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260228152602001806101c46022913960400191505060405180910390fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505060ab806101196000396000f3fe608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea264697066735822122003d1488ee65e08fa41e58e888a9865554c535f2c77126a82cb4c0f917f31441364736f6c63430007060033496e76616c69642073696e676c65746f6e20616464726573732070726f7669646564";

    /// @notice Gets the Limitless Safe 4337 address for a signer
    /// @param signer   - Address of the signer
    /// @param deployer - Address of the deployer contract
    // function getSafeAddress(address signer, address implementation, address deployer)
    function getSafeAddress(address signer, address deployer)
        internal
        pure
        returns (address safe)
    {

        uint256 saltNonce = 0;

        bytes32 bytecodeHash = keccak256(getContractBytecode(safeSingletonAddress));
        bytes memory initializer = _getInitializerCode(
            signer,
            ZERO_ADDRESS, // erc20TokenAddress
            ZERO_ADDRESS  // paymasterAddress
        );

        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));

        safe = _computeCreate2Address(deployer, bytecodeHash, salt);
    }

    function getContractBytecode(address masterCopy) internal pure returns (bytes memory) {
        return abi.encodePacked(proxyCreationCode, abi.encode(masterCopy));
    }

    function _computeCreate2Address(address deployer, bytes32 bytecodeHash, bytes32 salt)
        internal
        pure
        returns (address)
    {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }

    function _getInitializerCode(
        address owner,
        address erc20TokenAddress,
        address paymasterAddress
    ) internal pure returns (bytes memory) {
        InternalTx[] memory setupTxs = new InternalTx[](
            erc20TokenAddress != ZERO_ADDRESS && paymasterAddress != ZERO_ADDRESS ? 2 : 1
        );

        // Enable module transaction
        setupTxs[0] = InternalTx({
            to: addModuleLibAddress,
            data: _enableModuleCallData(),
            value: 0,
            operation: 1 // DelegateCall
        });

        // Add approve transaction if needed
        if (erc20TokenAddress != ZERO_ADDRESS && paymasterAddress != ZERO_ADDRESS) {
            setupTxs[1] = InternalTx({
                to: erc20TokenAddress,
                data: _generateApproveCallData(paymasterAddress),
                value: 0,
                operation: 0 // Call
            });
        }

        bytes memory multiSendCallData = _encodeMultiSend(setupTxs);

        address[] memory owners = new address[](1);
        owners[0] = owner;

        return abi.encodeWithSelector(
            ISafe.setup.selector,
            owners,
            1, // threshold
            multiSendAddress,
            multiSendCallData,
            safe4337ModuleAddress,
            ZERO_ADDRESS,
            0,
            payable(ZERO_ADDRESS)
        );
    }

    function _enableModuleCallData() internal pure returns (bytes memory) {
        address[] memory modules = new address[](1);
        modules[0] = safe4337ModuleAddress;

        return abi.encodeWithSignature("enableModules(address[])", modules);
    }

    function _generateApproveCallData(address spender) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("approve(address,uint256)", spender, type(uint256).max);
    }

    function _encodeMultiSend(InternalTx[] memory txs) internal pure returns (bytes memory) {
        bytes memory encodedTxs = "";

        for (uint256 i = 0; i < txs.length; i++) {
            encodedTxs = bytes.concat(
                encodedTxs,
                _encodeInternalTransaction(txs[i])
            );
        }

        return abi.encodeWithSignature("multiSend(bytes)", encodedTxs);
    }

    function _encodeInternalTransaction(InternalTx memory tx) internal pure returns (bytes memory) {
        return abi.encodePacked(
            tx.operation,
            tx.to,
            tx.value,
            uint256(tx.data.length),
            tx.data
        );
    }
}