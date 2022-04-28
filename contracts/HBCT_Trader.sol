// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./Security.sol";

pragma solidity ^0.8.9;

contract HBCT_Trader is Security {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable WETH;

    mapping(address => uint256) internal _isExcludedFromFee;

    address public HBCT;
    address public TOKEN;
    address public PAIR;
    address[] public _pathCONV;
    address[] public _pathTRADE;

    address private reciever;
    uint256 private feePerc;

    constructor(address tHBCT, address tTOKEN, address tUniswapV2Router) {
        HBCT = tHBCT;
        TOKEN = tTOKEN;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(tUniswapV2Router);
        uniswapV2Router = _uniswapV2Router;
        address _WETH = _uniswapV2Router.WETH();
        WETH = _WETH;
        PAIR = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(HBCT, TOKEN);

        _pathCONV = new address[](2);
        _pathCONV[0] = _WETH;
        _pathCONV[1] = TOKEN;

        _pathTRADE = new address[](2);
        _pathTRADE[0] = TOKEN;
        _pathTRADE[1] = HBCT;

        //exclude Owner, Contract & Pair from fee
        _isExcludedFromFee[owner()] = 1;
        _isExcludedFromFee[address(this)] = 1;
        _isExcludedFromFee[PAIR] = 1;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1) {
        (reserve0, reserve1,) = IUniswapV2Pair(PAIR).getReserves();
    }

    function withdrawStuckFunds() external onlyOwner {
        require(address(this).balance > 0);
        payable(_msgSender()).transfer(address(this).balance);
    }

    function withdrawStuckToken(address _token) external onlyOwner {
        address _spender = address(this);
        uint256 _balance = IERC20(_token).balanceOf(_spender);
        require(_balance > 0, "Can't withdraw Token with 0 balance");

        IERC20(_token).approve(_spender, _balance);
        IERC20(_token).transferFrom(_spender, _msgSender(), _balance);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account] == 1;
    }

     function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = 1;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = 0;
    }

    function setHBCT(address _hbct) external onlyOwner {
        HBCT = _hbct;
        _pathTRADE[1] = HBCT;
        PAIR = IUniswapV2Factory(uniswapV2Router.factory()).getPair(HBCT, TOKEN);
    }

    function setTOKEN(address _token) external onlyOwner {
        TOKEN = _token;
        _pathCONV[1] = TOKEN;
        _pathTRADE[0] = TOKEN;
        PAIR = IUniswapV2Factory(uniswapV2Router.factory()).getPair(HBCT, TOKEN);
    }

    function setFeeReciever(address _reciever) external onlyOwner {
        reciever = _reciever;
    }

    function setFee(uint256 _feePerc) external onlyOwner {
        if (_feePerc > 100) feePerc = 100;
        else feePerc = _feePerc;
    }

    function setPathCONV(address[] memory _CONV) external onlyOwner {
        _pathCONV = _CONV;
    }

    function setPathTRADE(address[] memory _TRADE) external onlyOwner {
        _pathTRADE = _TRADE;
    }

    function Trade() payable external {
        require(HBCT != address(0) && TOKEN != address(0), "Convert is not Setup.");
        require(reciever != address(0), "Contract is not Setup.");
        this.Swap{value: msg.value}(_msgSender());
    }

    function Swap(address sender) payable external onlyContr {
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, _pathCONV, address(this), block.timestamp);

        // Gett balance and substract fees
        uint256 _amTOKEN = IERC20(TOKEN).balanceOf(address(this));
        bool takeFee = _isExcludedFromFee[sender] == 0;

        if (feePerc > 0 && takeFee) {
            uint256 _feeSize = feePerc * _amTOKEN / 100;
            _amTOKEN -= _feeSize;

            // Transfer the fees
            IERC20(TOKEN).approve(reciever, _feeSize);
            IERC20(TOKEN).transfer(reciever, _feeSize);
        }
        
        // Swap the rest for tokens
        IERC20(TOKEN).approve(address(uniswapV2Router), _amTOKEN);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amTOKEN, 0, _pathTRADE, address(this), block.timestamp);

        // Transfer the token
        _amTOKEN = IERC20(HBCT).balanceOf(address(this));
        IERC20(HBCT).approve(sender, _amTOKEN);
        IERC20(HBCT).transfer(sender, _amTOKEN);
    }
}