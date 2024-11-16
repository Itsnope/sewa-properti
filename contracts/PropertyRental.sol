// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRental {
    struct Property {
        address payable owner;
        string name;
        string description;
        string location;
        uint pricePerDay;
        bool isRented;
        address currentRenter;
        uint rentalEndTime;
    }
    
    struct Rental {
        address renter;
        uint rentalDays;
        uint totalAmount;
        uint startTime;
        bool active;
    }
    
    Property[] public properties;
    mapping(uint => Rental[]) public rentals;
    
    event PropertyListed(uint propertyId, address owner, string name, string location, uint pricePerDay);
    event PropertyRented(uint propertyId, address renter, uint rentalDays, uint totalAmount);
    event RentalCancelled(uint propertyId, address renter);
    event RentalEnded(uint propertyId);

    function getPropertiesCount() public view returns (uint) {
        return properties.length;
    }
    
    function listProperty(string memory _name, string memory _description, string memory _location, uint _pricePerDay) public {
        require(_pricePerDay > 0, "Price must be greater than 0");
        Property memory newProperty = Property({
            owner: payable(msg.sender),
            name: _name,
            description: _description,
            location: _location,
            pricePerDay: _pricePerDay,
            isRented: false,
            currentRenter: address(0),
            rentalEndTime: 0
        });
        properties.push(newProperty);
        uint propertyId = properties.length - 1;
        emit PropertyListed(propertyId, msg.sender, _name, _location, _pricePerDay);
    }
    
    function rentProperty(uint _propertyId, uint _rentalDays) public payable {
        Property storage property = properties[_propertyId];
        require(msg.sender != property.owner, "Owner cannot rent their own property");
        require(!property.isRented, "Property already rented");
        require(_rentalDays > 0, "Rental days must be greater than 0");
        require(msg.value == property.pricePerDay * _rentalDays, "Incorrect rental amount");
        
        property.isRented = true;
        property.currentRenter = msg.sender;
        property.rentalEndTime = block.timestamp + (_rentalDays * 1 days);
        
        rentals[_propertyId].push(Rental({
            renter: msg.sender,
            rentalDays: _rentalDays,
            totalAmount: msg.value,
            startTime: block.timestamp,
            active: true
        }));
        
        property.owner.transfer(msg.value);
        emit PropertyRented(_propertyId, msg.sender, _rentalDays, msg.value);
    }
    
    function cancelRental(uint _propertyId) public {
        Property storage property = properties[_propertyId];
        Rental[] storage rentalArray = rentals[_propertyId];
        Rental storage currentRental = rentalArray[rentalArray.length - 1];
        
        require(msg.sender == property.currentRenter || msg.sender == property.owner, 
                "Only renter or owner can cancel");
        require(currentRental.active, "Rental not active");
        
        property.isRented = false;
        property.currentRenter = address(0);
        property.rentalEndTime = 0;
        currentRental.active = false;
        
        emit RentalCancelled(_propertyId, currentRental.renter);
    }
    
    function endRental(uint _propertyId) public {
        Property storage property = properties[_propertyId];
        Rental[] storage rentalArray = rentals[_propertyId];
        Rental storage currentRental = rentalArray[rentalArray.length - 1];
        
        require(msg.sender == property.owner, "Only owner can end rental");
        require(currentRental.active, "Rental not active");
        require(block.timestamp >= property.rentalEndTime, "Rental period not finished");
        
        property.isRented = false;
        property.currentRenter = address(0);
        property.rentalEndTime = 0;
        currentRental.active = false;
        
        emit RentalEnded(_propertyId);
    }
    
    function getRentalHistory(uint _propertyId) public view returns (Rental[] memory) {
        return rentals[_propertyId];
    }
}