// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Manufacturer {

    ManufactureOwner[] manufacturerList;
    uint manufacturerId = manufacturerList.length;

    mapping(address => bool) manufacturers;

    struct ManufactureOwner {
        uint manufacturerId;
        address manufacturerAccount;
        string manufacturerName;
        string manufactureLocation;
    }

    event NewManufacturerCreated(uint manufacturerId);
    event ManufacturerAdded(address manufacturerAccount);

    function createManufacturer(string memory _manufacturerName, string memory _manufactureLocation) onlyManufacturer public {
        address manufacturer = msg.sender;
        manufacturerList.push(ManufactureOwner(manufacturerId, manufacturer, _manufacturerName, _manufactureLocation));
        manufacturerId++;
        emit NewManufacturerCreated(manufacturerId);
    }


    // Function that determines that the address owner is the manufacturer
    function isManufacturer(address _account) public view returns (bool) {
        require(_account != address(0), "Manufacturer has no address");
        return manufacturers[_account];
    }

    // Checks if the msg sender is the manufacturer
    modifier onlyManufacturer() {
        require(isManufacturer(msg.sender), "Not a manufacturer");
        _;
    }

    function addManufacturer(address _account) public {
        require(_account != address(0), "Not manufacturer's account");
        require(!isManufacturer(_account), "Is not a manufacturer");

        manufacturers[_account] = true;
        emit ManufacturerAdded(_account);
    }

}

 