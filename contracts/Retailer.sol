// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract Retailer {

    RetailOwner[] retailerList;
    uint retailerId = retailerList.length;

    mapping(address => bool) retailers;

    struct RetailOwner {
        uint retailerId;
        address retailerAccount;
        string retailerName;
        string retailLocation;
    }

    event NewRetaileCreated(uint retailerId);
    event RetailerAdded(address retailerAccount);

    function createRetailer(string memory _retailerName, string memory _retailLocation) onlyRetailer public {
        address retailer = msg.sender;
        retailerList.push(RetailOwner(retailerId, retailer, _retailerName, _retailLocation));
        retailerId++;
        emit NewRetaileCreated(retailerId);
    }

    // Function that determines that the address owner is the retailer
    function isRetailer(address _account) public view returns (bool) {
        require(_account != address(0), "Retailer has no address");
        return retailers[_account];
    }

    // Checks if the msg sender is the retailer
    modifier onlyRetailer() {
        require(isRetailer(msg.sender), "Not a retailer");
        _;
    }

    function addRetailer(address _account) public {
        require(_account != address(0), "Not retailer's account");
        require(!isRetailer(_account), "Is not a retailer");

        retailers[_account] = true;
        emit RetailerAdded(_account);
    }
}