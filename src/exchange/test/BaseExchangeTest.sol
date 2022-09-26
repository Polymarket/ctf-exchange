// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { TestHelper } from "dev/TestHelper.sol";
import { USDC } from "dev/mocks/USDC.sol";
import { Deployer } from "dev/util/Deployer.sol";

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { CTFExchange } from "exchange/CTFExchange.sol";
import { IAuthEE } from "exchange/interfaces/IAuth.sol";
import { IFeesEE } from "exchange/interfaces/IFees.sol";
import { ITradingEE } from "exchange/interfaces/ITrading.sol";
import { IPausableEE } from "exchange/interfaces/IPausable.sol";
import { IRegistryEE } from "exchange/interfaces/IRegistry.sol";
import { ISignaturesEE } from "exchange/interfaces/ISignatures.sol";

import { IConditionalTokens } from "exchange/interfaces/IConditionalTokens.sol";

import { CalculatorHelper } from "exchange/libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus, SignatureType } from "exchange/libraries/OrderStructs.sol";

contract BaseExchangeTest is TestHelper, IAuthEE, IFeesEE, IRegistryEE, IPausableEE, ITradingEE, ISignaturesEE {
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _checkpoints1155;

    USDC public usdc;
    IConditionalTokens public ctf;
    CTFExchange public exchange;

    bytes32 public constant questionID = hex"1234";
    bytes32 public conditionId;
    uint256 public yes;
    uint256 public no;

    address public admin = alice;
    uint256 internal bobPK = 0xB0B;
    uint256 internal carlaPK = 0xCA414;
    address public bob;
    address public carla;

    // ERC20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC1155 transfer event
    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    function setUp() public virtual {
        bob = vm.addr(bobPK);
        vm.label(bob, "bob");
        carla = vm.addr(carlaPK);
        vm.label(carla, "carla");

        usdc = new USDC();
        vm.label(address(usdc), "USDC");
        ctf = IConditionalTokens(Deployer.ConditionalTokens());
        vm.label(address(ctf), "CTF");

        conditionId = _prepareCondition(admin, questionID);
        yes = _getPositionId(2);
        no = _getPositionId(1);

        vm.startPrank(admin);
        exchange = new CTFExchange(address(usdc), address(ctf), address(0), address(0));
        exchange.registerToken(yes, no, conditionId);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
    }

    function _prepareCondition(address oracle, bytes32 _questionId) internal returns (bytes32) {
        ctf.prepareCondition(oracle, _questionId, 2);
        return ctf.getConditionId(oracle, _questionId, 2);
    }

    function _getPositionId(uint256 indexSet) internal view returns (uint256) {
        return ctf.getPositionId(IERC20(address(usdc)), ctf.getCollectionId(bytes32(0), conditionId, indexSet));
    }

    function _createAndSignOrderWithFee(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 feeRateBps,
        Side side
    ) internal returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.feeRateBps = feeRateBps;
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createAndSignOrder(uint256 pk, uint256 tokenId, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        returns (Order memory)
    {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createOrder(address maker, uint256 tokenId, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        pure
        returns (Order memory)
    {
        Order memory order = Order({
            salt: 1,
            signer: maker,
            maker: maker,
            taker: address(0),
            tokenId: tokenId,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: 0,
            nonce: 0,
            feeRateBps: 0,
            signatureType: SignatureType.EOA,
            side: side,
            signature: new bytes(0)
        });
        return order;
    }

    function _signMessage(uint256 pk, bytes32 message) internal returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, message);
        sig = abi.encodePacked(r, s, v);
    }

    function _mintTestTokens(address to, address spender, uint256 amount) internal {
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        vm.startPrank(to);
        approve(address(usdc), address(ctf), type(uint256).max);

        dealAndApprove(address(usdc), to, spender, amount);
        IERC1155(address(ctf)).setApprovalForAll(spender, true);

        uint256 splitAmount = amount / 2;
        IConditionalTokens(ctf).splitPosition(IERC20(address(usdc)), bytes32(0), conditionId, partition, splitAmount);
        vm.stopPrank();
    }

    function assertCollateralBalance(address _who, uint256 _amount) public {
        assertBalance(address(usdc), _who, _amount);
    }

    function assertCTFBalance(address _who, uint256 _tokenId, uint256 _amount) public {
        assertBalance1155(address(ctf), _who, _tokenId, _amount);
    }

    function checkpointCollateral(address _who) public {
        checkpointBalance(address(usdc), _who);
    }

    function checkpointCTF(address _who, uint256 _tokenId) public {
        checkpointBalance1155(address(ctf), _who, _tokenId);
    }

    function getCTFBalance(address _who, uint256 _tokenId) public view returns (uint256) {
        return IERC1155(address(ctf)).balanceOf(_who, _tokenId);
    }

    function assertBalance1155(address _token, address _who, uint256 _tokenId, uint256 _amount) public {
        assertEq(getCTFBalance(_who, _tokenId), _checkpoints1155[_token][_who][_tokenId] + _amount);
    }

    function checkpointBalance1155(address _token, address _who, uint256 _tokenId) public {
        _checkpoints1155[_token][_who][_tokenId] = getCTFBalance(_who, _tokenId);
    }

    function calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) public pure returns (uint256) {
        return CalculatorHelper._calculatePrice(makerAmount, takerAmount, side);
    }

    function calculateFee(uint256 _feeRate, uint256 _amount, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        pure
        returns (uint256)
    {
        return CalculatorHelper.calculateFee(_feeRate, _amount, makerAmount, takerAmount, side);
    }

    function _getTakingAmount(uint256 _making, uint256 _makerAmount, uint256 _takerAmount)
        internal
        pure
        returns (uint256)
    {
        return _making * _takerAmount / _makerAmount;
    }
}
