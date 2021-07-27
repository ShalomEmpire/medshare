// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//import "./@openzeppelin/contracts-upgradeable/token/ERC777/extensions/ERC777SnapshotUpgradeable.sol";
//import "./@openzeppelin/contracts-upgradeable/token/ERC777/extensions/ERC777VotesUpgradeable.sol";
//import "./@openzeppelin/contracts-upgradeable/token/ERC777/extensions/draft-ERC777PermitUpgradeable.sol";

contract MedShareToken is Initializable, ERC777Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    AggregatorV3Interface internal priceETHUSDFeed;
    AggregatorV3Interface internal priceXAGUSDFeed;

    struct BiblicalPrinciples {
        uint256 fifth; // The fifth (Genesis4149)
        uint256 tenth; // The tenth (Genesis1420)
        uint256 twelfth; // The twelfth
        uint256 halfShekel; // Half Shekel
    }

    // This is the Imperial constant price for the Half Shekel: IhS (g/Oz) = 7 / 28.34
    uint256 constant IhS = 24700070;

    BiblicalPrinciples principles = BiblicalPrinciples(5, 10, 12, IhS);

    /**
     * @dev This is the initialize function that starts this Token.
     * It should be called as soon as possible.
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     * Aggregator: XAG/USD
     * Address: 0x9c1946428f4f159dB4889aA6B218833f467e1BfD
     */
    function initialize(
        uint256 initialSupply,
        address[] memory defaultOperators
    ) public initializer {
        __ERC777_init("MedShare Token", "MDST", defaultOperators);
        __Ownable_init();
        __UUPSUpgradeable_init();
        // __ERC777Permit_init("MedShareToken");
        // __ERC777Snapshot_init();

        // Price Feed for Rinkeby
        priceETHUSDFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        priceXAGUSDFeed = AggregatorV3Interface(
            0x9c1946428f4f159dB4889aA6B218833f467e1BfD
        );
        _mint(msg.sender, initialSupply, "", "");
    }

    // This is the a Stable Dollar contract address
    address stableDollarAddress = 0x3d2AeC4725b69e4fc5C1D9D75AcBfaCc1a4De4f5;
    IERC20Upgradeable sda = IERC20Upgradeable(address(stableDollarAddress));

    // If the user sends ETH to this Contract he will be able to refund back
    mapping(address => uint256) private _pendingWithdrawals;

    /**
     * @dev hTAG quotation in Dollars
     * @return result exchange rate htag/usd
     */
    function hTAGxDollars(uint256 amount) public view returns (uint256 result) {
        // Getting hTAG from XAG price and Exchanging USD for hTAG (MDST)
        return
            (amount * (principles.halfShekel * uint256(getXagUsdPrice()))) /
            10**(getXagUsdPriceDecimals() + 8);
    }

    /**
     * @dev Returns The latest ETH/USD price
     */
    function getEthUsdPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceETHUSDFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Returns ETH/USD price decimals
     */
    function getEthUsdPriceDecimals() public view returns (uint8) {
        return priceETHUSDFeed.decimals();
    }

    /**
     * @dev Returns The latest XAG/USD price
     */
    function getXagUsdPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceXAGUSDFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Returns XAG/USD price decimals
     */
    function getXagUsdPriceDecimals() public view returns (uint8) {
        return priceXAGUSDFeed.decimals();
    }

    /**
     * @dev Test the Imperial Principles
     * @param amount can be any positive value
     * @return result that should give the actual amount in half shekels
     */
    function testImperialPrinciples(uint256 amount)
        public
        view
        returns (uint256 result)
    {
        // Exchanging Amount of ETH for USD
        uint256 usd = (amount * uint256(getEthUsdPrice())) /
            10**getEthUsdPriceDecimals();
        // Getting hTAG from XAG price and Exchanging USD for hTAG (MDST)
        uint256 mdst = usd /
            ((principles.halfShekel * uint256(getXagUsdPrice())) /
                10**(getXagUsdPriceDecimals() + 8));
        return mdst;
    }

    /* function snapshot() public onlyOwner {
        _snapshot();
    } */

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /*  function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC777Upgradeable, ERC777SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    } */

    /* function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC777Upgradeable, ERC777VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    } */

    /*  function _mint(address to, uint256 amount)
        internal
        override(ERC777Upgradeable, ERC777VotesUpgradeable)
    {
        super._mint(to, amount);
    } */

    /* function _burn(address account, uint256 amount)
        internal
        override(ERC777Upgradeable, ERC777VotesUpgradeable)
    {
        super._burn(account, amount);
    } */

    /**
     * @dev Function to Withdraw funds that came to this contract without going
     * through the Invest() function.
     */
    function withdraw() external {
        require(
            _pendingWithdrawals[msg.sender] > 0,
            "MDST: No funds pending for this address"
        );

        uint256 amount = _pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        _pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    event Received(address, uint256);

    /**
     * @dev Function to receive Ether. msg.data must be empty
     * when someone sends Ether not passing through the Invest() function.
     */
    receive() external payable {
        _pendingWithdrawals[msg.sender] += msg.value;
        emit Received(msg.sender, msg.value);
    }

    event Fallenback(address, uint256);

    /**
     * @dev Function Fallback: It is called when msg.data is
     * not empty to receive Ether. (msg.data must be empty)
     * This happens when someone sends Ether not passing through
     * the Invest() function.
     */
    fallback() external payable {
        _pendingWithdrawals[msg.sender] += msg.value;
        emit Fallenback(msg.sender, msg.value);
    }
}
