// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./MedShareToken.sol";
import "./utils/StringsAndBytes.sol";

contract MedShare is MedShareToken {

    
    // Biblical Principles
    address storeHouseAddress = 0x7125fc5F7B09330a37D863fAb18aeBFdDf9f5382; // Genesis4149
    
   
    // Maps every family address to its own family name
    mapping(address => bytes32) private _familyNames;
    // Each account should be linked to one family
    mapping(address => address) private _userFamilies;
    // If the user has or not registered himself yet
    mapping(address => bool) private _registeredUsers;
    // Amount that every user has sown into his family (tenth)
    mapping(address => mapping(address => uint256)) private _shares;

    /**
     * @dev Test the Biblical Principles
     * @param amount can be any positive value
     * @return result that should give the same value of the input
     */
    function testBiblicalPrinciples(uint256 amount) public view returns (uint256 result) {
        uint256 cached = (amount * 6167) / 10000;
        uint256 fifth = amount / principles.fifth;
        uint256 twelfth = (amount * 833) / 10000;
        uint256 tenth = amount / principles.tenth;

        return cached + fifth + twelfth + tenth;
    }

    /**
     * @dev Sets another storeHouseAddress
     */
    function setStoreHouseAddress(address _storeHouseAddress) public onlyOwner {
        uint256 amount = balanceOf(storeHouseAddress);
        super.transfer(_storeHouseAddress, amount);
        storeHouseAddress = _storeHouseAddress;
    }
    
    /**
     * @dev Return family address
     */
    function getFamilyAddress(string memory _familyName) public pure returns (address) {
        bytes32 _familyNameB32 = keccak256(abi.encodePacked(_familyName));
        return address(uint160(uint256(_familyNameB32)));
    }
    
    /**
     * @dev Return caller family address
     */
    function getCallerFamilyAddress() public view returns (address) {
        return _userFamilies[msg.sender];
    }
    
    /**
     * @dev Return family name
     */
    function getFamilyName(address _familyAddress) public view returns (string memory) {
        return StringsAndBytes.bytes32ToString(_familyNames[_familyAddress]);
    }
    
    /**
     * @dev Retrieve the family name for a specific person's address.
     * We may increase the security for this search*
     */
    function getUserFamilyName(address _userAddress) public view returns (string memory) {
        address _familyAddress = _userFamilies[_userAddress];
        return StringsAndBytes.bytes32ToString(_familyNames[_familyAddress]);
    }
    
    /**
     * @dev Return user's family name
     */
    function getMyFamilyName() public view returns (string memory) {
        address _familyAddress = _userFamilies[msg.sender];
        return StringsAndBytes.bytes32ToString(_familyNames[_familyAddress]);
    }
    
    /**
     * @dev Return family's balance in MDST
     */
    function getFamilyBalance(string memory _familyName) public view returns (uint256) {
        address _familyAddress = getFamilyAddress(_familyName);
        return balanceOf(_familyAddress);
    }
   
    /**
     * @dev Return my family's balance in MDST
     */
    function getMyFamilyBalance() public view returns (uint256) {
        address _myFamilyAddress = _userFamilies[msg.sender];
        return balanceOf(_myFamilyAddress);
    }
    
    event Register( 
        address _from, 
        address _familyAddress,
        string _familyNameStr,
        bytes32 _familyName
    );
    
    /**
     * @dev Register the user using his family name.
     */
    function register(string memory _familyName) public returns (address) {
        require(!_registeredUsers[msg.sender], "MDST: You are already registered in a Family");
        
        address _familyAddress = getFamilyAddress(_familyName);
        bytes32 _familyNameB32;
        
        if (_familyNames[_familyAddress] == bytes32(0x0)) {
            _familyNameB32 = StringsAndBytes.stringToBytes32(_familyName);
            _familyNames[_familyAddress] = _familyNameB32;
        }
    
        _userFamilies[msg.sender] = _familyAddress;
        _registeredUsers[msg.sender] = true;
        
        emit Register(msg.sender, _familyAddress, _familyName, _familyNameB32);
        return _familyAddress;
    }
    
    event RegisterMember( 
        address _from, 
        address _familyAddress,
        string _familyNameStr,
        bytes32 _familyNameB32
    );
    
     /**
     * @dev Register a user using a family name.
     */
    function registerMember(address _userAddress, string memory _familyName) public returns (address) {
        require(!_registeredUsers[msg.sender], "MDST: This account is already registered in a Family");
        
        address _familyAddress = getFamilyAddress(_familyName);
        bytes32 _familyNameB32;
        
        if (_familyNames[_familyAddress] == bytes32(0x0)) {
            _familyNameB32 = StringsAndBytes.stringToBytes32(_familyName);
            _familyNames[_familyAddress] = _familyNameB32;
        }
        
        _userFamilies[_userAddress] = _familyAddress;
        _registeredUsers[_userAddress] = true;
        
        emit RegisterMember(_userAddress, _familyAddress, _familyName, _familyNameB32);
        
        return _familyAddress;
    }

    event Invest( 
        address _from,
        address _familyAddress,
        uint256 _amountEth,
        uint256 _cached,
        uint256 _shares
    );

    /**
     * @dev Invest in my Family
     */
    function invest() public payable returns (address) {
        require(msg.sender != address(0x0), "MDST: It cannot invest to the zero address");
        require(_registeredUsers[msg.sender], "MDST: You are not yet registered in a Family");

        // Exchanging ETH for USD
        uint256 usd = (msg.value * uint256(getEthUsdPrice())) / 10**getEthUsdPriceDecimals();
        // Getting hTAG from XAG price and Exchanging USD for hTAG (MDST)
        uint256 mdst = usd / ((principles.halfShekel * uint256(getXagUsdPrice())) / 10**(getXagUsdPriceDecimals() + 8));

        uint256 cached = (mdst * 6167) / 10000;
        uint256 fifth = mdst / principles.fifth;
        uint256 tenth = mdst / principles.tenth;
        uint256 twelfth = (mdst * 833) / 10000;

        address _familyAddress = _userFamilies[msg.sender];
        
        _mint(msg.sender, cached, "", "");
        _mint(storeHouseAddress, fifth, "", "");
        _mint(_familyAddress, tenth, "", "");
        _mint(owner(), twelfth, "", "");

        _shares[_familyAddress][msg.sender] += tenth;
        
        emit Invest(msg.sender, _familyAddress, msg.value, cached, tenth);
        
        return _userFamilies[msg.sender];
    }
    
     event InvestInAFamily( 
        address _from,
        address _familyAddress,
        uint256 _amountEth,
        uint256 _shares
    );
    
    /**
     * @dev Invest in a Family not being registered in that family
     */
    function investInAFamily(string memory _familyName) public payable returns (bool) {
        require(msg.sender != address(0), "MDST: It cannot invest to the zero address");
        
        // Exchanging ETH for USD
        uint256 usd = (msg.value * uint256(getEthUsdPrice())) / 10**getEthUsdPriceDecimals();
        // Getting hTAG from XAG price and Exchanging USD for hTAG (MDST)
        uint256 mdst = usd / ((principles.halfShekel * uint256(getXagUsdPrice())) / 10**(getXagUsdPriceDecimals() + 8));

        uint256 investment = (mdst * 7167) / 10000; // tenth plus cached
        uint256 fifth = mdst / principles.fifth;
        uint256 twelfth = (mdst * 833) / 10000;

        address _familyAddress = getFamilyAddress(_familyName);
        bytes32 _familyNameB32;
        
        if (_familyNames[_familyAddress] == bytes32(0x0)) {
            _familyNameB32 = StringsAndBytes.stringToBytes32(_familyName);
            _familyNames[_familyAddress] = _familyNameB32;
        }
        
        // Larger amount minted to this family
        _mint(_familyAddress, investment, "", "");
        _mint(storeHouseAddress, fifth, "", "");
        _mint(owner(), twelfth, "", "");

        // This time the shares are bigger to the caller
        _shares[_familyAddress][msg.sender] += investment;
        
        emit InvestInAFamily(msg.sender, _familyAddress, msg.value, investment);
        
        return true;
    }
    
    event InvestInAFamilyAddress( 
        address _from,
        address _familyAddress,
        uint256 _amountEth,
        uint256 _shares
    );
    
    /**
     * @dev Invest in a Family not being registered in that family
     */
    function investInAFamilyAddress(address _familyAddress) public payable returns (string memory) {
        require(msg.sender != address(0), "MDST: It cannot invest to the zero address");
        require(_familyNames[_familyAddress] != bytes32(0x0), "MDST: Address does not correspond to a family address");
        
        // Exchanging ETH for USD
        uint256 usd = (msg.value * uint256(getEthUsdPrice())) / 10**getEthUsdPriceDecimals();
        // Getting hTAG from XAG price and Exchanging USD for hTAG (MDST)
        uint256 mdst = usd / ((principles.halfShekel * uint256(getXagUsdPrice())) / 10**(getXagUsdPriceDecimals() + 8));

        uint256 investment = (mdst * 7167) / 10000; // tenth plus cached
        uint256 fifth = mdst / principles.fifth;
        uint256 twelfth = (mdst * 833) / 10000;
        
        // Larger amount minted to this family
        _mint(_familyAddress, investment, "", "");
        _mint(storeHouseAddress, fifth, "", "");
        _mint(owner(), twelfth, "", "");

        // This time the shares are bigger to the caller
        _shares[_familyAddress][msg.sender] += investment;
        
        emit InvestInAFamilyAddress(msg.sender, _familyAddress, msg.value, investment);
        
        return getFamilyName(_familyAddress);
    }

    /**
     * @dev Function to query this contract's Stable Dollars reserve balance
     */
    function getContractStableDollarsBalance() external view returns (uint256) {
        // transfers stable Dollars that belong to your contract to the specified address
        return sda.balanceOf(address(this));
    }

    /**
     * @dev Function to Send ETH to Stable Dollars contract
     */
    function sendEthToStableDollarsContract(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "MDST: No balance found for that amount");
        
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = address(sda).call{value: _amount}("");
        
        require(sent, "MDST: Failed to send Ether to a Stable Dollars Contract");
    }

    /**
     * @dev Function to Send Stable Dollars to another address using this Contract's Stable Dollars Balance
     * inside Stable Dollars Contract.
     */
    function sendStableDollars(address _to, uint256 _amount) external onlyOwner {
        require(
            sda.balanceOf(address(this)) >= _amount,
            "StableDollarContract: No balance found for that amount"
        );
        // transfers Dollars that belong to this contract to the specified address _to
        sda.transfer(_to, _amount);
    }
    
    /**
     * @dev Contract's balance in ETHER.
     */
    function totalContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Function to Withdraw certain amount
     * of funds in ETHER. This method is here
     * so the Owner can be able to withdraw funds
     * in case that there is a need
     * of exchanging the amount of ETHER stored
     * in this contract for some other Asset, Fiat or the Like.
     */
    function withdrawSome(uint256 amount) external onlyOwner {
        require(
            address(this).balance >= amount,
            "MDST: No balance found for that amount"
        );
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Function to Withdraw all funds in ETHER.
     * This method is here if there is a need
     * of exchanging the amount of ETHER stored
     * in this contract.
     */
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}
