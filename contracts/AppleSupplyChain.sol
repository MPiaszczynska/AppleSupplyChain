// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Farmer.sol";
import "./Manufacturer.sol";
import "./Retailer.sol";
import "./DateTimeLibrary.sol";

contract AppleSupplyChain is Farmer, Manufacturer, Retailer {

    using DateTimeLibrary for DateTimeLibrary.DateTime;

    // The supply chain stages for the product
    enum ProductState {
        NewProductAdded,            // 0
        HarvestedByFarmer,          // 1
        ShippedByFarmer,            // 2
        ReceivedByManufacturer,     // 3
        ProductAddedToBatch,        // 4
        ProductPacked,              // 5
        ProductShippedToRetailer,   // 6
        ProductReceivedByRetailer,  // 7
        ProductApprovedForSale      // 8
        }

    // Product type that contains detailed product information
    struct Product {
        uint productId;             // original product identifier 
        uint index;                 // initially 0, when item is selected for batch original product id is stored in this 
        uint batchId;               // initially 0, updated when product selected to batch
        uint barcode;               // product barcode
        uint farmerId;              // farmer id
        string productName;         // name of the product
        string productCategory;     // category of the product
        string farmerName;          // farmer's name
        uint date;                  // block timestamp
        address owner;              // contract owner at each stage
        ProductState productState;  // stae of the product at each stage
    }

    // A struct to store product information through the supply chain stages
    struct ProductTraceability {
        Product[] productTrace;
    }

    // Global variables for array indexes that will be increamented
    uint public productId = products.length;
    uint public index = productsToBatch.length;

    // Arrays of Product structs initialised as global variables
    Product[] products;
    Product[] productsToBatch;
    
    // mappings for quick lookups
    mapping(uint => Product) productList;
    mapping(uint => ProductTraceability) productTraceability;
    mapping(uint => mapping(uint => Product[])) batchProduct;

    
    event NewProductAdded(uint productId);
    event HarvestedByFarmer(uint productId);
    event ShippedByFarmer(uint productId);
    event ReceivedByManufacturer(uint productId);
    event ProductsSelected(uint productId);
    event ProductAdded(uint productId);
    event PackedByManufacturer(uint productId);
    event ShippedToRetailer(uint productId);
    event ReceivedByRetailer(uint productId);
    event ApprovedForSale(uint productId);

    // A list of modifiers that check if the product is in correct state for the given stage in the supply chain
    modifier newProductAdded(uint _productId) {
        require(products[_productId].productState == ProductState.NewProductAdded, "No product added");
        _;
    }
     modifier harvestedByFarmer(uint _productId) {
        require(products[_productId].productState == ProductState.HarvestedByFarmer, "Product not harvested");
        _;
    }
    modifier shippedByFarmer(uint _productId) {
        require(products[_productId].productState == ProductState.ShippedByFarmer, "Product not shipped by farmer");
        _;
    }
    modifier receivedByManufacturer(uint _productId) {
        require(products[_productId].productState == ProductState.ReceivedByManufacturer, "Product not received by manufacturer");
        _;
    }
    modifier productAddedToBatch(uint _productId) {
        require(productsToBatch[_productId].productState == ProductState.ProductAddedToBatch, "No product added");
        _;
    }
    modifier packedByManufacturer(uint _productId) {
        require(productsToBatch[_productId].productState == ProductState.ProductPacked, "Product not packed");
        _;
    }
    modifier shippedToRetailer(uint _productId) {
        require(productsToBatch[_productId].productState == ProductState.ProductShippedToRetailer, "Product not shipped to retailer");
        _;
    }
    modifier receivedByRetailer(uint _productId) {
        require(productsToBatch[_productId].productState == ProductState.ProductReceivedByRetailer, "Product not received by retailer");
        _;
    }
    modifier approvedForSale(uint _productId) {
        require(productsToBatch[_productId].productState == ProductState.ProductApprovedForSale, "Product not ready for sale");
        _;
    }

    /**
        AddProduct function that adds new product to the database and can be only executed by farmer
    */
    function addProduct(
        uint _barcode,
        uint _farmerId,
        string memory _productName,
        string memory _productCategory) 
        onlyFarmer public {

            FarmOwner storage newFarmer = Farmer.farmerList[_farmerId]; // An instance of a Farmer contract
            string memory farmerName = newFarmer.farmerName;    // Assigning farmer's name stored on Farmer.sol contract
            uint date = block.timestamp;
            address owner = msg.sender;
            products.push(Product(productId, 0, 0, _barcode, _farmerId, farmerName, _productName, 
                _productCategory, date, 
                owner, ProductState.NewProductAdded));
            productList[productId] = products[productId]; // Saving initial product details to prodctList mapping
            productTraceability[productId].productTrace.push(products[productId]);  // Updating traceability storage
            productId++;

            emit NewProductAdded(productId); 
    }

    /**
        harvestProduct function that can only be executed by farmer when the product was added
     */
    function harvestProduct(uint _productId) newProductAdded(_productId) onlyFarmer public {

        products[_productId].date = block.timestamp;
        products[_productId].productState = ProductState.HarvestedByFarmer;
        productTraceability[_productId].productTrace.push(products[_productId]);

        emit HarvestedByFarmer(_productId);        
    }

     /**
        sendToManufacturer function that can only be executed by farmer when the product was harvested
     */
    function sendToManufacturer(uint _productId) harvestedByFarmer(_productId) onlyFarmer public {

        products[_productId].date = block.timestamp;
        products[_productId].productState = ProductState.ShippedByFarmer;
        productTraceability[_productId].productTrace.push(products[_productId]);

        emit ShippedByFarmer(_productId); 
    }
     /**
        receiveByManufacturer function that can only be executed by manufacturer when the product was shipped to manufacturer
     */
    function receiveByManufacturer(uint _productId) shippedByFarmer(_productId) onlyManufacturer public {

        products[_productId].owner = msg.sender;
        products[_productId].date = block.timestamp;
        products[_productId].productState = ProductState.ReceivedByManufacturer;
        productTraceability[_productId].productTrace.push(products[_productId]); 

        emit ReceivedByManufacturer(_productId);             
    }
     /**
        selectProductForBatch function that can only be executed by manufacturer when the product was received by manufacturer
     */
    function selectProductForBatch(uint _batchId, uint _productId) receivedByManufacturer(_productId) onlyManufacturer public {
        
        // Product details are copied to new variables
        uint newProductId = products[_productId].productId;
        newProductId = index;
        uint origProductId = _productId;
        uint newBarcode = products[_productId].barcode;
        uint newFarmerId = products[_productId].farmerId;
        string memory newProductName = products[_productId].productName;
        string memory newProductCategory = products[_productId].productCategory;
        string memory newFarmerName = products[_productId].farmerName;
        uint date = block.timestamp; 
        address owner = msg.sender;
        ProductState productState = ProductState.ProductAddedToBatch;

        // New array created with the copied values and a new product id
        productsToBatch.push(Product(newProductId, origProductId, _batchId, newBarcode, newFarmerId, newProductName, newProductCategory, newFarmerName, date, owner, productState));
        index++;

        batchProduct[_batchId][newProductId].push(productsToBatch[newProductId]);
        productTraceability[_productId].productTrace.push(productsToBatch[newProductId]); 

        emit ProductAdded(newProductId);
    }
     /**
        packProduct function that can only be executed by manufacturer when the product was selected for batch
     */
    function packProduct(uint _batchId, uint _productId) productAddedToBatch(_productId) onlyManufacturer public {

        if (productsToBatch[_productId].batchId == _batchId) {
            uint origProductId = productsToBatch[_productId].index;
            productsToBatch[_productId].date = block.timestamp;
            productsToBatch[_productId].productState = ProductState.ProductPacked;
            
            batchProduct[_batchId][_productId].push(productsToBatch[_productId]);
            productTraceability[origProductId].productTrace.push(productsToBatch[_productId]);
        } else {
            revert("Incorrect batch id");
        }
        
        emit PackedByManufacturer(_productId);        
    }
     /**
        shipProductToRetailer function that can only be executed by manufacturer when the product was packed
     */
    function shipProductToRetailer(uint _batchId, uint _productId) packedByManufacturer(_productId) onlyManufacturer public {

        if (productsToBatch[_productId].batchId == _batchId) {
            uint origProductId = productsToBatch[_productId].index;
            productsToBatch[_productId].date = block.timestamp;
            productsToBatch[_productId].productState = ProductState.ProductShippedToRetailer;

            batchProduct[_batchId][_productId].push(productsToBatch[_productId]);
            productTraceability[origProductId].productTrace.push(productsToBatch[_productId]);
        } else {
            revert("Incorrect batch id");
        }
        emit ShippedToRetailer(_productId);    
    }
     /**
        receiveByRetailer function that can only be executed by retailer when the product was shipped to retailer
     */
    function receiveByRetailer(uint _batchId, uint _productId) shippedToRetailer(_productId) onlyRetailer public {
        
        if (productsToBatch[_productId].batchId == _batchId) {
            uint origProductId = productsToBatch[_productId].index;
            productsToBatch[_productId].owner = msg.sender;
            productsToBatch[_productId].date = block.timestamp;
            productsToBatch[_productId].productState = ProductState.ProductReceivedByRetailer;

            batchProduct[_batchId][_productId].push(productsToBatch[_productId]);
            productTraceability[origProductId].productTrace.push(productsToBatch[_productId]);
        } else {
            revert("Incorrect batch id");
        }
        emit ReceivedByRetailer(_productId);      
    }
     /**
        productReadyForSale function that can only be executed by retailer when the product was received by retailer
     */
    function productReadyForSale(uint _batchId, uint _productId) receivedByRetailer(_productId) onlyRetailer public {

        if (productsToBatch[_productId].batchId == _batchId) {
            uint origProductId = productsToBatch[_productId].index;
            productsToBatch[_productId].date = block.timestamp;
            productsToBatch[_productId].productState = ProductState.ProductApprovedForSale;

            batchProduct[_batchId][_productId].push(productsToBatch[_productId]);
            productTraceability[origProductId].productTrace.push(productsToBatch[_productId]);
        } else {
            revert("Incorrect batch id");
        }
        emit ApprovedForSale(_productId);    

    }

    /**
        A function that returns full traceablity data for the product
     */
    function getTraceabilityData(uint _productId) public view returns (ProductTraceability memory) {
        return productTraceability[_productId];
    }

    // function getProductData(uint _productId) public view returns (Product memory) {
    //     return productList[_productId];
    // }

    // function getAllProducts() public view returns (Product[] memory) {
    //     Product[] memory pList = new Product[](productId);
    //     for (uint i = 0; i < products.length; i++) {
    //         Product memory prod = productList[i];
    //         pList[i] = prod;
    //     }
    //     return pList;
    // }

    function getBatchProducts(uint _batchId) public view returns (Product[] memory) {
        Product[] memory pList = new Product[](index);
        for (uint i = 0; i < productsToBatch.length; i++) {
            if (productsToBatch[i].batchId == _batchId) {
                Product memory prod = productsToBatch[i];
                pList[i] = prod;
            } else {
                revert("No batch found");
            }
        }
        return pList;
    }

    // function getProductsInBatch(uint _batchId, uint _productId) public view returns (Product[] memory) {
    //     return batchProduct[_batchId][_productId];
    // }
    
}


