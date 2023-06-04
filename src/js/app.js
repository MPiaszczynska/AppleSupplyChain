App = {
  web3Provider: null,
  accounts: null,
  contracts: {},
  emptyAddress: "0x0000000000000000000000000000000000000000",
  productId: 0,
  productId1: 1,
  productId2: 2,
  barcode: 111111,
  date: 1650479392,
  owner: "0x0000000000000000000000000000000000000000",
  productName: "Apples",
  productCategory: "Fruit",
  farmerAddress: "0x0000000000000000000000000000000000000000",
  farmerAddress1: "0x0000000000000000000000000000000000000000",
  farmerAddress2: "0x0000000000000000000000000000000000000000",
  farmerId: 0,
  farmerName: "John Apple",
  farmLocation: "South Wales",
  farmerId1: 1,
  farmerName1: "Bob Applepie",
  farmLocation1: "East Wakes",
  farmerId2: 2,
  farmerName2: "Tom Appletree",
  farmLocation2: "North Wales",
  manufacturerAddress: "0x0000000000000000000000000000000000000000",
  manufacturerName: "Apple & Co.",
  manufacturerLocation: "England",
  retailerAddress: "0x0000000000000000000000000000000000000000",
  retailerName: "Apple Store",
  retailerLocation: "Scotland",
  batchId: 0,
  // productState: 0,

  init: async function () {
      App.fillUpForm();
      /// Setup access to blockchain
      return await App.initWeb3();
  },

  fillUpForm: function () {
      $("#productId").val(App.productId);
      $("#productId1").val(App.productId1);
      $("#productId2").val(App.productId2);
      $("#barcode").val(App.barcode);
      $("#date").val(App.date);
      $("#owner").val(App.owner);
      $("#productName").val(App.productName);
      $("#productCategory").val(App.productCategory);
      $("#farmerAddress").val(App.farmerAddress);
      $("#farmerAddress1").val(App.farmerAddress1);
      $("#farmerAddress2").val(App.farmerAddress2);
      $("#farmerId").val(App.farmerId);
      $("#farmerName").val(App.farmerName);
      $("#farmLocation").val(App.farmLocation);
      $("#farmerId1").val(App.farmerId1);
      $("#farmerName1").val(App.farmerName1);
      $("#farmLocation1").val(App.farmLocation1);
      $("#farmerId2").val(App.farmerId2);
      $("#farmerName2").val(App.farmerName2);
      $("#farmLocation2").val(App.farmLocation2);
      $("#manufacturerAddress").val(App.manufacturerAddress);
      $("#manufacturerName").val(App.manufacturerName);
      $("#manufacturerLocation").val(App.manufacturerLocation);
      $("#retailerAddress").val(App.retailerAddress);
      $("#retailerName").val(App.retailerName);
      $("#retailerLocation").val(App.retailerLocation);
      $("#batchId").val(App.batchId);


      console.log(
        App.productId,
        App.productId1,
        App.productId2,
        App.barcode,
        App.date, 
        App.owner, 
        App.productName, 
        App.productCategory,
        App.farmerAddress,
        App.farmerAddress1,
        App.farmerAddress2,
        App.farmerId,
        App.farmerName,
        App.farmLocation,
        App.farmerId1,
        App.farmerName1,
        App.farmLocation1,
        App.farmerId2,
        App.farmerName2,
        App.farmLocation2,
        App.manufacturerAddress,
        App.manufacturerName,
        App.manufacturerLocation,
        App.retailerAddress,
        App.retailerName,
        App.retailerLocation,
        App.batchId
      );
  },

  initWeb3: async function () {
      /// Find or Inject Web3 Provider
      /// Modern dapp browsers...
      if (window.ethereum) {
          App.web3Provider = window.ethereum;
          try {
              // Request account access
              await window.ethereum.enable();
          } catch (error) {
              // User denied account access...
              console.error("User denied account access")
          }
      }
      // Legacy dapp browsers...
      else if (window.web3) {
          App.web3Provider = window.web3.currentProvider;
      }
      // If no injected web3 instance is detected, fall back to Truffle
      else {
          App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      }
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');

      App.getOwnerAddress();

      return App.initAppleAppleSupplyChain();
  },

  getOwnerAddress: function () {
    
      web3 = new Web3(App.web3Provider);

      // Retrieving accounts
      web3.eth.getAccounts(function(err, res) {
          if (err) {
              console.log('Error:',err);
              return;
          }
          console.log('getMetaskID:',res);
          App.owner = res[0];
          App.accounts = res;

          App.setupAccounts();
      });
  },

  setupAccounts: function() {
      App.farmerAddress = App.accounts[1];
      App.farmerAddress1 = App.accounts[2];
      App.farmerAddress2 = App.accounts[3];
      App.manufacturerAddress = App.accounts[4];
      App.retailerAddress = App.accounts[5];

      App.updateAccounts();
  },

  updateAccounts: function() {
      $("#owner").val(App.owner);
      $("#farmerAddress").val(App.farmerAddress);
      $("#farmerAddress1").val(App.farmerAddress1);
      $("#farmerAddress2").val(App.farmerAddress2);
      $("#manufacturerAddress").val(App.manufacturerAddress);
      $("#retailerAddress").val(App.retailerAddress);
  },

  initAppleAppleSupplyChain: function () {
      /// Source the truffle compiled smart contracts
      let jsonAppleAppleSupplyChain='../../build/contracts/AppleAppleSupplyChain.json';
      
      /// JSONfy the smart contracts
      $.getJSON(jsonAppleAppleSupplyChain, function(data) {
          console.log('data',data);
          let AppleAppleSupplyChainArtifact = data;
          App.contracts.AppleAppleSupplyChain = TruffleContract(AppleAppleSupplyChainArtifact);
          App.contracts.AppleAppleSupplyChain.setProvider(App.web3Provider);
          
          App.getProductData();
          App.getTraceabilityData();
          App.getEvents();

      });

      return App.bindEvents();
  },

  bindEvents: function() {
      $("button").on('click', App.handleButtonClick);
  },

  handleButtonClick: async function(event) {
      event.preventDefault();

      App.getOwnerAddress();

      let stateId = parseInt(event.target.id);

      switch(stateId) {
        case 1:
            return await App.newProductAdded(event);
        case 2:
            return await App.harvestedByFarmer(event);
        case 3:
            return await App.shippedByFarmer(event);
        case 4:
            return await App.receivedByManufacturer(event);
        case 5:
            return await App.productAddedToBatch(event);
        case 6:
            return await App.packedByManufacturer(event);
        case 7:
            return await App.shippedToRetailer(event);
        case 8:
            return await App.receivedByRetailer(event);
        case 9:
            return await App.approvedForSale(event);
        case 10:
            return await App.getTraceabilityData(event);
        }
  },

  newProductAdded: function(event) {
      event.preventDefault();
      var stateId = parseInt($(event.target).data('id'));
      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.n(
              App.barcode, 
              App.farmerId,
              App.productName,
              App.productCategory, 
              App.date, 
              {
                  from: App.farmerAddress,
                  gas: 3000000,
              }
          );
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('newProductAdded',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  harvestedByFarmer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.harvestedByFarmer(App.productId, {from: App.farmerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('harvestedByFarmer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },
  
  shippedByFarmer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.shippedByFarmer(App.productId, {from: App.originFarmerID});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('shippedByFarmer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  receivedByManufacturer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.receivedByManufacturer(App.productId, {from: App.manufacturerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('receivedByManufacturer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  packedByManufacturer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.packedByManufacturer(App.productId, {from: App.manufacturerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('packedByManufacturer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  shippedByManufacturer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.shippedByManufacturer(App.productId, {from: App.manufacturerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('shippedByManufacturer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  receivedByRetailer: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.receivedByRetailer(App.productId, {from: App.retailerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('receivedByRetailer',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

  approvedForSale: function (event) {
      // event.preventDefault();
      // let stateId = parseInt($(event.target).data('id'));

      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
          return instance.approvedForSale(App.productId, {from: App.retailerAddress});
      }).then(function(result) {
          $("#ftc-item").text(result);
          console.log('approvedForSale',result);
      }).catch(function(err) {
          console.log(err.message);
      });
  },

//   getProductData: function () {
//   ///   event.preventDefault();
//   ///    var stateId = parseInt($(event.target).data('id'));
//       App.productId = $('#productId').val();
//       console.log('productId',App.productId);

//       App.contracts.AppleSupplyChain.deployed().then(function(instance) {
//         return instance.getProductData(App.productId);
//       }).then(function(result) {
//         $("#ftc-item").text(result);
//         console.log('getProductData', result);
//       }).catch(function(err) {
//         console.log(err.message);
//       });
//   },

  getTraceabilityData: function () {
  ///    event.preventDefault();
  ///    var stateId = parseInt($(event.target).data('id'));
                      
      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
        return instance.getTraceabilityData.call(App.productId);
      }).then(function(result) {
        $("#ftc-item").text(result);
        console.log('getTraceabilityData', result);
      }).catch(function(err) {
        console.log(err.message);
      });
  },

  getEvents: function () {
      if (typeof App.contracts.AppleSupplyChain.currentProvider.sendAsync !== "function") {
          App.contracts.AppleSupplyChain.currentProvider.sendAsync = function () {
              return App.contracts.AppleSupplyChain.currentProvider.send.apply(
              App.contracts.AppleSupplyChain.currentProvider,
                  arguments
            );
          };
      }
      App.contracts.AppleSupplyChain.deployed().then(function(instance) {
        let events = instance.allEvents(function(err, log){
        console.log('hello', log)
        if (!err)
          $("#ftc-events").append('<li>' + log.event + ' - ' + log.transactionHash + '</li>');
      });
      }).catch(function(err) {
        console.log(err.message);
      });

  }
};

$(function () {
  $(window).load(function () {
      App.init();
  });
});