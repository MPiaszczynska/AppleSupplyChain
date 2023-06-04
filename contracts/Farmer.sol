// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Farmer {

    struct FarmOwner {
        uint farmerId;
        address farmerAccount;
        string farmerName;
        string farmLocation;
    }

    FarmOwner[] farmerList;
    uint farmerId = farmerList.length;
    address private farmerAccount;

    mapping(address => bool) farmers;

    constructor() public {
        farmerAccount = msg.sender;
    }

    event NewFarmerCreated(uint farmerId);

    function createFarmer(string memory _farmerName, string memory _farmLocation) onlyFarmer() public {
        farmerList.push(FarmOwner(farmerId, farmerAccount, _farmerName, _farmLocation));
        farmerId++;
        emit NewFarmerCreated(farmerId);
    }

    function farmer() public view returns (address) {
        return farmerAccount;
    }

     // Function that determines that the address owner is the farmer
    function isFarmer(address _account) public view returns (bool) {
        require(_account != address(0), "Farmer has no address");
        return farmers[_account];
    }

    // Checks if the msg sender is the farmer
    modifier onlyFarmer() {
        require(isFarmer(msg.sender), "Not a farmer");
        _;
    }

    function addFarmer(address _account) public {
        require(_account != address(0), "Not farmer's account");
        require(!isFarmer(_account), "Is not a farmer");

        farmers[_account] = true;
    }

    function getFarmerDetails(uint _farmerId) public view returns (FarmOwner memory) {
        return farmerList[_farmerId];
    }


}