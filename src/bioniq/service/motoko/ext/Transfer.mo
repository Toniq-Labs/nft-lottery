import ExtCore "Core";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";

module ExtTransfer
{
    type TokenIndex  = ExtCore.TokenIndex ;
    type AccountIdentifier = ExtCore.AccountIdentifier;
  
    public func _removeTokenFromUser(tindex : TokenIndex,  _registry : HashMap.HashMap<TokenIndex, AccountIdentifier>,  _owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]> ) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex, _registry);
    _registry.delete(tindex);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o, _owners);
      case (_) {};
    };
  };

    public func _transferTokenToUser(tindex : TokenIndex, receiver : AccountIdentifier, _registry : HashMap.HashMap<TokenIndex, AccountIdentifier>, _owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]> ) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex, _registry);
    _registry.put(tindex, receiver);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o, _owners);
      case (_) {};
    };
    _addToUserTokens(tindex, receiver, _owners);
  };
  public func _removeFromUserTokens(tindex : TokenIndex, owner : AccountIdentifier,_owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]> ) : () {
    switch(_owners.get(owner)) {
      case(?ownersTokens) _owners.put(owner, Array.filter(ownersTokens, func (a : TokenIndex) : Bool { (a != tindex) }));
      case(_) ();
    };
  };
  public func _addToUserTokens(tindex : TokenIndex, receiver : AccountIdentifier,  _owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]>) : () {
    let ownersTokensNew : [TokenIndex] = switch(_owners.get(receiver)) {
      case(?ownersTokens) Array.append(ownersTokens, [tindex]);
      case(_) [tindex];
    };
    _owners.put(receiver, ownersTokensNew);
  };
  public func _getBearer(tindex : TokenIndex, _registry : HashMap.HashMap<TokenIndex, AccountIdentifier> ) : ?AccountIdentifier {
    _registry.get(tindex);
  };
}