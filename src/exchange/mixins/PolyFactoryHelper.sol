// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { PolySafeLib } from "../libraries/PolySafeLib.sol";
import { PolyProxyLib } from "../libraries/PolyProxyLib.sol";

interface IPolyProxyFactory {
    function getImplementation() external view returns (address);
}

interface IPolySafeFactory {
    function masterCopy() external view returns (address);
}

abstract contract PolyFactoryHelper {
    /// @notice The Polymarket Proxy Wallet Factory Contract
    address public proxyFactory;
    /// @notice The Polymarket Gnosis Safe Factory Contract
    address public safeFactory;

    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);

    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;
    }

    /// @notice Gets the Proxy factory address
    function getProxyFactory() public view returns (address) {
        return proxyFactory;
    }

    /// @notice Gets the Safe factory address
    function getSafeFactory() public view returns (address) {
        return safeFactory;
    }

    /// @notice Gets the Polymarket Proxy factory implementation address
    function getPolyProxyFactoryImplementation() public view returns (address) {
        return IPolyProxyFactory(proxyFactory).getImplementation();
    }

    /// @notice Gets the Safe factory implementation address
    function getSafeFactoryImplementation() public view returns (address) {
        return IPolySafeFactory(safeFactory).masterCopy();
    }

    /// @notice Gets the Polymarket proxy wallet address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getPolyProxyWalletAddress(address _addr) public view returns (address) {
        return PolyProxyLib.getProxyWalletAddress(_addr, getPolyProxyFactoryImplementation(), proxyFactory);
    }

    /// @notice Gets the Polymarket Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return PolySafeLib.getSafeAddress(_addr, getSafeFactoryImplementation(), safeFactory);
    }

    function _setProxyFactory(address _proxyFactory) internal {
        emit ProxyFactoryUpdated(proxyFactory, _proxyFactory);
        proxyFactory = _proxyFactory;
    }

    function _setSafeFactory(address _safeFactory) internal {
        emit SafeFactoryUpdated(safeFactory, _safeFactory);
        safeFactory = _safeFactory;
    }
}
