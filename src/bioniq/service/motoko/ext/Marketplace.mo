
import ExtCore "Core";
import Time "mo:base/Time";
import Result "mo:base/Result";
import AID "../util/AccountIdentifier";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";


module ExtMarketplace
{
  type TokenIndex  = ExtCore.TokenIndex ;
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type CommonError = ExtCore.CommonError;
  type Time = Time.Time;

  public type Transaction = {
    token : TokenIndex;
    seller : AccountIdentifier;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
  public type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
  };
  public type ListRequest = {
    token : TokenIdentifier;
    from_subaccount : ?SubAccount;
    price : ?Nat64;
  };
  public  type PaymentType = {
    #sale : Nat64;
    #nft : TokenIndex;
    #nfts : [TokenIndex];
  };
  public  type Payment = {
    purchase : PaymentType;
    amount : Nat64;
    subaccount : SubAccount;
    payer : AccountIdentifier;
    expires : Time;
  };
   public type SaleTransaction = {
    tokens : [TokenIndex];
    seller : Principal;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
   public type SaleDetailGroup = {
    id : Nat;
    name : Text;
    start : Time;
    end : Time;
    available : Bool;
    pricing : [(Nat64, Nat64)];
  };
   public type SaleDetails = {
    start : Time;
    end : Time;
    groups : [SaleDetailGroup];
    quantity : Nat;
    remaining : Nat;
  };
   public type SaleSettings = {
    price : Nat64;
    salePrice : Nat64;
    sold : Nat;
    remaining : Nat;
    startTime : Time;
    whitelistTime : Time;
    whitelist : Bool;
    totalToSell : Nat;
    bulkPricing : [(Nat64, Nat64)];
  };
   public type SalePricingGroup = {
    name : Text;
    limit : (Nat64, Nat64); //user, group
    start : Time;
    end : Time;
    pricing : [(Nat64, Nat64)]; //qty,price
    participants : [AccountIdentifier];
  };
  public  type SaleRemaining = {#burn; #send : AccountIdentifier; #retain;};
  public  type Sale = {
    start : Time; //Start of first group
    end : Time; //End of first group
    groups : [SalePricingGroup];
    quantity : Nat; //Tokens for sale, set by 0000 address
    remaining : SaleRemaining;
  };

 public func ext_marketplacePurchase(tokenid : TokenIdentifier, price : Nat64, buyer : AccountIdentifier, actorPrincipal : Principal, _tokenListing : HashMap.HashMap<TokenIndex, Listing>, subaccount : SubAccount,_paymentSettlements : HashMap.HashMap<AccountIdentifier, Payment> ) : Result.Result<(AccountIdentifier, Nat64), CommonError> {
    		if (ExtCore.TokenIdentifier.isPrincipal(tokenid, actorPrincipal) == false) {
			return #err(#InvalidToken(tokenid));
		};
		let token = ExtCore.TokenIdentifier.getIndex(tokenid);
		switch(_tokenListing.get(token)) {
			case (?listing) {
        if (listing.price != price) {
          return #err(#Other("Price has changed!"));
        } else {
          return #ok(ext_addPayment(#nft(token), price, buyer, subaccount, actorPrincipal, _paymentSettlements), price);
        };
			};
			case (_) {
				return #err(#Other("No listing!"));				
			};
		};
 };

   func ext_addPayment(purchase : PaymentType, amount : Nat64, payer : AccountIdentifier, subaccount : SubAccount, actorPrincipal : Principal, _paymentSettlements : HashMap.HashMap<AccountIdentifier, Payment>) : AccountIdentifier {
    let paymentAddress : AccountIdentifier = AID.fromPrincipal(actorPrincipal, ?subaccount);
    _paymentSettlements.put(paymentAddress, {
      purchase = purchase;
      amount = amount;
      subaccount = subaccount;
      payer = payer;
      expires = (Time.now() + (2* 60 * 1_000_000_000));
    });
    paymentAddress;
  };

 public func _ext_internal_marketplaceList(caller : Principal, request: ListRequest, config_marketplace_open : Time, data_saleCurrent : ?Sale, data_saleTokensForSale : [TokenIndex], actorPrincipal : Principal, _registry : HashMap.HashMap<TokenIndex, AccountIdentifier>, _tokenListing : HashMap.HashMap<TokenIndex, Listing>) : async Result.Result<(), CommonError> {
    if (Time.now() < config_marketplace_open) {
      if (_saleEnded(data_saleCurrent, data_saleTokensForSale) == false){
        return #err(#Other("You can not list yet"));
      };
    };
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, actorPrincipal) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    let owner = AID.fromPrincipal(caller, request.from_subaccount);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if(AID.equal(owner, token_owner) == false) {
					return #err(#Other("Not authorized"));
				};
        switch(request.price) {
          case(?price) {
            _tokenListing.put(token, {
              seller = caller;
              price = price;
              locked = null;
            });
          };
          case(_) {
            _tokenListing.delete(token);
          };
        };
        return #ok;
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };

  func _saleEnded(data_saleCurrent : ?Sale, data_saleTokensForSale : [TokenIndex]) : Bool {
    switch(data_saleCurrent) {
      case(?s){        
        if (Time.now() >= s.end or data_saleTokensForSale.size() == 0) {
          return true;
        } else {
          return false;
        };
      };
      case(_) return true;
    };
  };


  
};