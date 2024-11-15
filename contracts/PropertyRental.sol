// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyRental {
    struct Property {
        address payable owner;
        string name;
        string description;
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
    mapping(uint => Rental) public rentals;
    
    event PropertyListed(uint propertyId, address owner, string name, uint pricePerDay);
    event PropertyRented(uint propertyId, address renter, uint rentalDays, uint totalAmount);
    event RentalCancelled(uint propertyId, address renter);
    event RentalEnded(uint propertyId);
    
    // Mendapatkan jumlah total properti
    function getPropertiesCount() public view returns (uint) {
        return properties.length;
    }
    
    // Mendaftarkan properti baru
    function listProperty(string memory _name, string memory _description, uint _pricePerDay) public {
        require(_pricePerDay > 0, "Price must be greater than 0");
        Property memory newProperty = Property({
            owner: payable(msg.sender),
            name: _name,
            description: _description,
            pricePerDay: _pricePerDay,
            isRented: false,
            currentRenter: address(0),
            rentalEndTime: 0
        });
        properties.push(newProperty);
        uint propertyId = properties.length - 1;
        emit PropertyListed(propertyId, msg.sender, _name, _pricePerDay);
    }
    
    // Menyewa properti dengan pengecekan owner
    function rentProperty(uint _propertyId, uint _rentalDays) public payable {
        Property storage property = properties[_propertyId];
        require(msg.sender != property.owner, "Owner cannot rent their own property");
        require(!property.isRented, "Property already rented");
        require(_rentalDays > 0, "Rental days must be greater than 0");
        require(msg.value == property.pricePerDay * _rentalDays, "Incorrect rental amount");
        
        property.isRented = true;
        property.currentRenter = msg.sender;
        property.rentalEndTime = block.timestamp + (_rentalDays * 1 days);
        
        rentals[_propertyId] = Rental({
            renter: msg.sender,
            rentalDays: _rentalDays,
            totalAmount: msg.value,
            startTime: block.timestamp,
            active: true
        });
        
        property.owner.transfer(msg.value);
        emit PropertyRented(_propertyId, msg.sender, _rentalDays, msg.value);
    }
    
    // Membatalkan penyewaan
    function cancelRental(uint _propertyId) public {
        Property storage property = properties[_propertyId];
        Rental storage rental = rentals[_propertyId];
        
        require(msg.sender == property.currentRenter || msg.sender == property.owner, 
                "Only renter or owner can cancel");
        require(rental.active, "Rental not active");
        
        property.isRented = false;
        property.currentRenter = address(0);
        property.rentalEndTime = 0;
        rental.active = false;
        
        emit RentalCancelled(_propertyId, rental.renter);
    }
    
    // Mengakhiri masa sewa
    function endRental(uint _propertyId) public {
        Property storage property = properties[_propertyId];
        Rental storage rental = rentals[_propertyId];
        
        require(msg.sender == property.owner, "Only owner can end rental");
        require(rental.active, "Rental not active");
        require(block.timestamp >= property.rentalEndTime, "Rental period not finished");
        
        property.isRented = false;
        property.currentRenter = address(0);
        property.rentalEndTime = 0;
        rental.active = false;
        
        emit RentalEnded(_propertyId);
    }
    
    // Mengecek apakah address adalah owner dari properti
    function isPropertyOwner(uint _propertyId, address _address) public view returns (bool) {
        return properties[_propertyId].owner == _address;
    }
    
    // Mendapatkan detail properti
    function getProperty(uint _propertyId) public view returns (
        address owner,
        string memory name,
        string memory description,
        uint pricePerDay,
        bool isRented,
        address currentRenter,
        uint rentalEndTime
    ) {
        Property memory property = properties[_propertyId];
        return (
            property.owner,
            property.name,
            property.description,
            property.pricePerDay,
            property.isRented,
            property.currentRenter,
            property.rentalEndTime
        );
    }
    
    // Mendapatkan detail penyewaan
    function getRental(uint _propertyId) public view returns (
        address renter,
        uint rentalDays,
        uint totalAmount,
        uint startTime,
        bool active
    ) {
        Rental memory rental = rentals[_propertyId];
        return (
            rental.renter,
            rental.rentalDays,
            rental.totalAmount,
            rental.startTime,
            rental.active
        );
    }
    
    // Mendapatkan properti yang dimiliki oleh user tertentu
    function getMyProperties() public view returns (uint[] memory) {
        uint count = 0;
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].owner == msg.sender) {
                count++;
            }
        }
        
        uint[] memory myProperties = new uint[](count);
        uint currentIndex = 0;
        
        for (uint i = 0; i < properties.length; i++) {
            if (properties[i].owner == msg.sender) {
                myProperties[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return myProperties;
    }
    
    // Mendapatkan properti yang disewa oleh user tertentu
    function getMyRentals() public view returns (uint[] memory) {
        uint count = 0;
        for (uint i = 0; i < properties.length; i++) {
            if (rentals[i].renter == msg.sender && rentals[i].active) {
                count++;
            }
        }
        
        uint[] memory myRentals = new uint[](count);
        uint currentIndex = 0;
        
        for (uint i = 0; i < properties.length; i++) {
            if (rentals[i].renter == msg.sender && rentals[i].active) {
                myRentals[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return myRentals;
    }
}