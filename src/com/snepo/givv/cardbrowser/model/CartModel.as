package com.snepo.givv.cardbrowser.model
{
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.utils.*;

	public class CartModel extends EventDispatcher
	{

		public static const COINS : String = "CartModel.COINS";
		public static const NOTES : String = "CartModel.NOTES";
		public static const CARDS : String = "CartModel.CARDS";

		public static const REFERENCE_TYPE_WOOLWORTHS_EDR = "wow_edr";

		protected var _cartItems : Array = [];
		protected var _transactionFees : Array = [];
		protected var _transactionReferences : Array = [];
		protected var _cardTypeSelected : String = "";

		protected var _savedCarts : Dictionary = new Dictionary();
		protected var _paymentMethod : String = CARDS;

		public function CartModel()
		{
			super( this );
		}

		public function set paymentMethod ( p : String ) : void
		{
			_paymentMethod = p;

			if ( p == CARDS ) Model.getInstance().user.clearUser();

			dispatchEvent ( new CartEvent ( CartEvent.PAYMENT_METHOD_CHANGED ) );
		}

		public function get paymentMethod ( ) : String
		{
			return _paymentMethod;
		}

		public function saveCart ( cartItems : Array, guid : String ) : void
		{
			_savedCarts [ guid ] = cartItems;
		}

		public function getSavedCart ( guid : String ) : Array
		{
			return _savedCarts[guid] || [];
		}

		public function loadCart ( cart : Array ) : void
		{
			drain();

			for ( var i : int = 0; i < cart.length; i++ )
			{
				addItem ( cart[i] );
			}
		}
		/*
		public function getScanNumberByID ( productID : String ) : String
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				if ( (item.card.id + "") == productID )
				{
					if ( item.rechargePin )
					{
						return item.rechargePin;
					}else
					{
						return item.scanNumber;
					}
				}
			}

			return "";
		}
*/

		public function addItem ( d : Object, limitCheck : Boolean = true, updating : Boolean = false ) : void
		{

			var maxCards : int = Model.getInstance().host.maxCartCards;

			if ( limitCheck && ( totalCardsInCart + d.amount > maxCards ) )
			{
				dispatchEvent ( new CartEvent ( CartEvent.MAX_CARDS_REACHED ) );
				return;
			}

			var totalPriceOfNewItem : Number = d.amount * d.perCard;
			var newTotalPrice : Number = totalPriceOfNewItem + total;
			var cartLimit : Number = Model.getInstance().host.maxCartValue

			if ( paymentMethod == COINS && Model.getInstance().user.hasUser )
			{
				cartLimit = Model.getInstance().user.applicableBalance < cartLimit ? Model.getInstance().user.applicableBalance : cartLimit;
			}

			if ( newTotalPrice > cartLimit && limitCheck )
			{
				dispatchEvent ( new CartEvent ( CartEvent.LIMIT_REACHED, cartLimit ) );
				return;
			}

			Logger.beginTimer( "Adding " + d.amount + "x " + d.card.name + " " + StringUtil.currencyLabelFunction(d.perCard) + " (" + d.card.processas + ") to cart..." );

			if ( d.scanNumber != null ) // new scan item
			{
				if ( containsScannedItem( d ) )
				{
					if ( !updating )
						dispatchEvent ( new CartEvent ( CartEvent.SCANNED_CARD_EXISTS ) );
					Logger.endTimer("Scanned item already in cart");
					return;
				}
				else
				{
					if ( !hasItemMatchingPrice( d ) )
					{
						d.scanNumbers = new Array;
						d.scanNumbers.push(d.scanNumber);
						d.scanNumber = null;
						_cartItems.push ( d );
						dispatchEvent ( new CartEvent ( CartEvent.ITEM_ADDED, d ) );
						Logger.endTimer("New scannable item");
						return;
					}
				}
			}

			if ( hasItemMatchingPrice( d ) )
			{
				if ( contains ( d ) ) removeItem ( d );
				appendAmountToExistingItem ( d )
				dispatchEvent ( new CartEvent ( CartEvent.ITEM_UPDATED ) )
				Logger.endTimer("Existing Item");
				return;
			}

			if ( !contains(d) )
			{
				_cartItems.push ( d );
				dispatchEvent ( new CartEvent ( CartEvent.ITEM_ADDED, d ) );
				Logger.endTimer("New item");
				return;
			}

			Logger.endTimer("No new item");
		}

		public function addTransactionFee ( feeItem : Object ) : void
		{
			_transactionFees = []; // Only allow one item for now
			_transactionFees.push ( feeItem );
		}

		public function clearTransactionFees ( ) : void
		{
			_transactionFees = [];
		}

		public function get transactionFees ( ) : Array
		{
			return _transactionFees;
		}

		public function addTransactionReference ( referenceItem : Object ) : void
		{
			_transactionReferences.push ( referenceItem );
		}

		public function clearTransactionReferences ( ) : void
		{
			_transactionReferences = [];
		}

		public function get transactionReferences ( ) : Array
		{
			return _transactionReferences;
		}

		public function containsScannedItem ( d : Object ) : Boolean
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				if (cartItems[i].scanNumbers != null)
				{
					for ( var s : int = 0; s < cartItems[i].scanNumbers.length; s++ )
						if ( cartItems[i].scanNumbers[s] == d.scanNumber ) return true;
				}
			}

			return false;
		}

		public function getPrinterQueue ( ) : XML
		{
			var output : XML = <cart><kioskuniqid>{Environment.KIOSK_UNIQUE_ID}</kioskuniqid></cart>;
			var itemNode : XML = <items/>

			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				var node : XML;
				if (item.hasAdjustedValue)
				{
					node = 	<item>
										<productid>{item.card.id}</productid>
										<qty>{item.amount}</qty>
										<value>{item.adjustedPerCard.toFixed(4)}</value>
										<fee>{item.fee}</fee>
										<commission>{item.commission}</commission>
										<cost>{item.adjustedValue.toFixed(4)}</cost>
									</item>
				}
				else
				{
					node = 	<item>
										<productid>{item.card.id}</productid>
										<qty>{item.amount}</qty>
										<value>{item.perCard}</value>
									</item>
				}

				// new scannable activation method
				if ( item.scanNumbers != null )
				{
					var scanNode : XML = <numbers/>
					for ( var s : int = 0; s < item.scanNumbers.length; s++ )
					{
						scanNode.appendChild ( <number>{item.scanNumbers[s]}</number> );
					}
					node.appendChild ( scanNode )
				}
				itemNode.appendChild ( node );
			}

			// Transaction Fees
			var feeNode : XML = <transactionFees/>
			for ( var j : int = 0; j < _transactionFees.length; j++ )
			{
				feeNode.appendChild ( 	<transactionFee>
																	<type>{_transactionFees[j].feeType}</type>
																	<percentage>{_transactionFees[j].percentage}</percentage>
																	<cost>{_transactionFees[j].cost}</cost>
																</transactionFee> );
			}

			// Transaction References
			var referenceNode : XML = <transactionReferences/>
			for ( j = 0; j < _transactionReferences.length; j++ )
			{
				referenceNode.appendChild ( 	<transactionReference>
														    			<type>{_transactionReferences[j].type}</type>
																			<data>{_transactionReferences[j].data}</data>
																			</transactionReference> );
			}

			output.appendChild ( <paymentMethod>{hostPaymentMethod}</paymentMethod> );
			output.appendChild ( itemNode );
			output.appendChild ( feeNode );
			output.appendChild ( referenceNode );
			output.appendChild ( <totalPaid>{this.commissionedTotal}</totalPaid> );

			return output;
		}

		public function contains ( d : Object ) : Boolean
		{
			return _cartItems.indexOf ( d ) > -1;
		}

		public function removeItem ( d : Object ) : void
		{
			if ( contains ( d ) ) removeItemAt ( _cartItems.indexOf ( d ) );
		}

		public function injectResponse ( cards : XMLList ) : void
		{
			for ( var c : int = 0; c < cards.length(); c++ )
			{
				var card : XML = cards[c];
				for ( var i : int = 0; i < cartItems.length; i++ )
				{
					var item : Object = cartItems[i];
					if ( ( item.card.id + "") == (card.productid.text() + "") && !item.injected )
					{
						if ( card.@processas == CardModel.SCANNABLE || card.@processas == CardModel.VIRTUAL )
						{
							item.transactionID = ( card.@id ) + "";
							item.rechargePin = ( card.rechargepin.text() );
						}
						item.advertisingMessage = card.advertisingMessage;
						item.injected = true;
						break;
					}
				}
			}
		}

		public function getPrintableCartItems() : Array
		{
			var out : Array = [];
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				if ( item.scanNumbers == null ) out.push ( item );
			}

			return out;
		}

		public function removeItemAt ( index : int ) : void
		{
			var item : Object = _cartItems[index];
			_cartItems.splice ( index, 1 );
			dispatchEvent ( new CartEvent ( CartEvent.ITEM_REMOVED, item ) );

			if ( _cartItems.length == 0 ) dispatchEvent ( new CartEvent ( CartEvent.DRAIN ) );
		}

		public function hasItemMatchingPrice ( d : Object ) : Boolean
		{
			for ( var i : int = 0; i < _cartItems.length; i++ )
			{
				var item : Object = _cartItems[i];
				if ( item == d ) continue;
				if ( item.card == d.card && item.perCard == d.perCard ) return true;
			}

			return false;
		}

		public function appendAmountToExistingItem ( d : Object ) : void
		{
			for ( var i : int = 0; i < _cartItems.length; i++ )
			{
				var item : Object = _cartItems[i];
				if ( item.card == d.card && item.perCard == d.perCard )
				{
					item.amount += d.amount;

					// add scan number
					if ( d.scanNumber != null )
					{
						item.scanNumbers.push(d.scanNumber);
						trace("Scanable cart item contains cards - " + item.scanNumbers.toString());
					}
					// add scan numbers
					if ( d.scanNumbers != null )
					{
						for (var j : int = 0; j < d.scanNumbers.length; j++ )
							item.scanNumbers.push(d.scanNumbers[j]);
					}
				}
			}

		}

		public function get totalCardsInCart ( ) : int
		{
			var cards : int = 0;

			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				cards += item.amount;
			}

			return cards;
		}

		public function get hostPaymentMethod ( ) : String
		{
			switch ( paymentMethod )
			{
				case CartModel.CARDS:
					return "card";
				case CartModel.COINS:
					return "coin";
				case CartModel.NOTES:
					return "note";
				default:
					return "";
			}
		}

		public function applyUpdate ( source : Object, diff : Object ) : void
		{
			var oldPriceOfItem : Number = source.amount * source.perCard;
			var newPriceOfItem : Number = diff.amount * diff.perCard;
			var deltaPriceOfItem : Number = ( newPriceOfItem - oldPriceOfItem );
			var maxCards : int = Model.getInstance().host.maxCartCards;

			var cardAmountDelta : int = diff.amount - source.amount;
			var currentCardAmount : int = totalCardsInCart + cardAmountDelta;

			Logger.log( "Updating " + source.amount + "x " + source.card.name + " " + StringUtil.currencyLabelFunction(source.perCard) + " (" + source.card.processas + ") to " + diff.amount + "x " + StringUtil.currencyLabelFunction(diff.perCard) );

			if ( currentCardAmount > maxCards )
			{
				dispatchEvent ( new CartEvent ( CartEvent.MAX_CARDS_REACHED ) );
				return;
			}

			var newTotalPrice = deltaPriceOfItem + total;
			var cartLimit : Number = Model.getInstance().host.maxCartValue;

			if ( paymentMethod == COINS && Model.getInstance().user.hasUser )
			{
				cartLimit = Model.getInstance().user.applicableBalance < cartLimit ? Model.getInstance().user.applicableBalance : cartLimit;
			}

			if ( newTotalPrice > cartLimit )
			{
				dispatchEvent ( new CartEvent ( CartEvent.LIMIT_REACHED, cartLimit ) );
				return;
			}

			for ( var i : String in diff )
			{
				try
				{
					source[i] = diff[i];
				}catch ( e : Error )
				{
					trace ( "Error patching item with key => " + i );
				}
			}

			addItem ( source, false, true );

			dispatchEvent ( new CartEvent ( CartEvent.ITEM_UPDATED ) );
		}

		public function removeAppliedChanges ( ) : void
		{
			trace('CartModel::removeAppliedChanges()');
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
					delete item.fee;
					delete item.commission;
					delete item.hasAdjustedValue;
					delete item.adjustedPerCard;
					delete item.adjustedValue;
					delete item.hasError;
					delete item.errorObject;
			}

			dispatchEvent ( new CartEvent ( CartEvent.COMMISSION_APPLIED ) );
		}

		public function get isCharityPurchase ( ) : Boolean
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				if ( cartItems[i].card.api != "charity" ) return false;
			}

			return true;
		}

		public function applyReviewedChanges ( data : XML ) : Boolean
		{
			var items : XMLList = data..item;
			var hasErrors : Boolean = false;

			for ( var i : int = 0; i < items.length(); i++ )
			{
				var item : XML = items[i];
				var cartItem : Object = getCardItemByProductIDAndValue ( item.productid.text() + "", item.value.text() + "" );
				var adjustment : XML = item.adjustment[0];

				cartItem.hasAdjustedValue = true;
				cartItem.fee = Number ( adjustment.fee.text() ) || 0;
				cartItem.commission = Number ( adjustment.commission.text() ) || 0;
				cartItem.adjustedValue = Number ( adjustment.appliedValue.text() ) || 0;
				cartItem.adjustedPerCard = Number ( adjustment.appliedPerCard.text() ) || 0;

				if ( adjustment.error.text().length() > 0 )
				{
					cartItem.hasError = true;
					cartItem.errorObject = ErrorManager.getErrorByCode ( adjustment.error.text() );
					hasErrors = true;
				}else
				{
					cartItem.hasError = false;
					delete cartItem.errorObject;
				}
			}

			dispatchEvent ( new CartEvent ( CartEvent.COMMISSION_APPLIED ) );

			return hasErrors;
		}

		public function get cartHasReviewedItems ( ) : Boolean
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				if ( cartItems[i].hasAdjustedValue ) return true;
			}

			return false;
		}

		protected function getCardItemByProductID ( id : String ) : Object
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				if ( ( item.card.id + "" ) == id ) return item;
			}

			return null;
		}

		protected function getCardItemByProductIDAndValue ( id : String, value : String ) : Object
		{
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				if ( ((item.card.id + "") == id) && (Number(item.perCard + "") == Number(value)) ) return item;
			}

			return null;
		}

		public function get total ( ) : Number
		{
			var sum : Number = 0;
			var perCard : Number = 0;

			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				perCard = cartItems[i].hasAdjustedValue ? cartItems[i].adjustedPerCard : perCard = cartItems[i].perCard;
				var rawAmount : Number = ( cartItems[i].amount * perCard );

				sum += rawAmount;
			}

			return sum;
		}

		public function get commissionedEstimateTotal ( ) : Number
		{
			var sum : Number = 0;

			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var rawAmount : Number = ( cartItems[i].amount * cartItems[i].perCard );
				if ( cartItems[i].card.partnerID )
				{
					var commish : Object = Model.getInstance().partners.getCommissionAndFees ( ( cartItems[i].card.partnerID + "" ), paymentMethod );
					rawAmount += ( cartItems[i].amount * commish.fees );
					if ( commish.commission != 0 )
					{
						rawAmount *= ( 1 + ( commish.commission / 100 ) );
					}
				}

				sum += rawAmount;
			}

			return sum;
		}

		public function get commissionedTotal ( ) : Number
		{
			var sum : Number = 0;

			var totalCardFee : Number = 0;
			var totalCardValue : Number = 0;
			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var amount : Number = ( cartItems[i].amount * cartItems[i].perCard );
				if ( cartItems[i].hasAdjustedValue ) // always true after review
				{
					amount = cartItems[i].amount * cartItems[i].adjustedValue;
					totalCardFee += cartItems[i].amount * cartItems[i].fee;
					totalCardValue += cartItems[i].amount * cartItems[i].adjustedPerCard;
				}
				sum += amount;
			}

			// add transaction fees
			if (totalCardValue > 0)
			{
				for ( i = 0; i < _transactionFees.length; i++ )
				{
					_transactionFees[i].cost = (_transactionFees[i].percentage / 100) * ((totalCardFee-(totalCardFee/11)) + totalCardValue);
					sum += _transactionFees[i].cost;
				}
			}

			trace('CartModel::commissionedTotal() = ' + sum.toString());
			return sum;
		}

		public function get cartItems ( ) : Array
		{
			return _cartItems;
		}

		public function drain ( ) : void
		{
			_cartItems = [];
			_transactionFees = [];
			_transactionReferences = [];
			dispatchEvent ( new CartEvent ( CartEvent.DRAIN ) );
		}

		public function minFee ( paymentMethod : String )
		{
			var minFee : Number = 0;
			var totalFees : Number = 0;

			for ( var i : int = 0; i < cartItems.length; i++ )
			{
				var item : Object = cartItems[i];
				totalFees = Model.getInstance().partners.getCommissionedPrice ( item.card.partnerID, paymentMethod, { price : item.perCard } ) - item.perCard;
				if (totalFees > 0 && (minFee == 0 || totalFees < minFee))
					minFee = totalFees;
			}
			return minFee;
		}

		public function adjustCartForOverPayment ( additionalCard : Object, newTotal : Number )
		{
			var item : Object = {};
			var newItem : Object = {};
			var adjustableCardsInCart : Number = 0;
			var totalCardsInCart : Number = this.totalCardsInCart;
			var currentTotal : Number = this.commissionedTotal;
			var cardsAdjusted : Number = 0;
			var totalAdjusted : Number = 0;
			var totalToAdjust : Number = 0;
			var perCardToAdjust : Number = 0;
			var adjustedPerCard : Number = 0;
			var i : int;

			if (cartHasReviewedItems) // only adjust a reviewed cart
			{
				// find number of variable value cards in cart
				for ( i = 0; i < cartItems.length; i++ )
				{
					item = cartItems[i];
					if (item.card.allowUserValue)
						adjustableCardsInCart += item.amount;
				}

				if (adjustableCardsInCart == 0)
				{
					// add extra card with difference
					var data : Object = { };
					data.card = additionalCard;
					data.amount = 1;
					data.perCard = newTotal - currentTotal;
					addItem( data );
				}
				else
				{
					totalToAdjust = newTotal - currentTotal;
					perCardToAdjust = Math.round(totalToAdjust / adjustableCardsInCart);
					trace ('CartModel::adjustCartForOverPayment() - adjustableCardsInCart = ' + adjustableCardsInCart.toString() +
						   ', totalToAdjust = ' + (newTotal-currentTotal).toString() +
						   ', perCardToAdjust = ' + perCardToAdjust.toString());

					cardsAdjusted = 0;
					var itemCount = cartItems.length; // store in variable incase new item is added
					for ( i = 0; i < itemCount; i++ )
					{
						item = cartItems[i];
						newItem = {};
						if (item.card.allowUserValue)
						{
							if (totalAdjusted < totalToAdjust)
							{
								// handle scenario where applying remaining overspend would go over the total
								if ((totalAdjusted + (perCardToAdjust * item.amount)) > totalToAdjust)
								{
									if (item.amount == 1)
									{
										adjustedPerCard = totalToAdjust - totalAdjusted;
										item.perCard = item.adjustedValue + adjustedPerCard;
										totalAdjusted += adjustedPerCard;
										cardsAdjusted += 1;
										trace ('CartModel::adjustCartForOverPayment() - Cart item added with remaining value (before = ' + item.adjustedValue + ', after = ' + item.perCard + ', qty = ' + item.amount + ')');
									}
									else
									{
										// remove 1 card from cart item and share remaining value
										adjustedPerCard = Math.round((totalToAdjust-totalAdjusted)/item.amount);
										applyUpdate ( item, { amount : item.amount-1, perCard : item.adjustedValue + adjustedPerCard } );
										totalAdjusted += adjustedPerCard * item.amount;
										cardsAdjusted += item.amount;
										trace ('CartModel::adjustCartForOverPayment() - Cart item split with remaining value (before = ' + item.adjustedValue + ', after = ' + item.perCard + ', qty = ' + item.amount + ')');
										// add new cart item with remaining value
										newItem = copyCartItem(item);
										newItem.amount = 1;
										adjustedPerCard = totalToAdjust - totalAdjusted;
										newItem.perCard = item.adjustedValue + adjustedPerCard;
										addItem( newItem );
										totalAdjusted += adjustedPerCard;
										cardsAdjusted += newItem.amount;
										trace ('CartModel::adjustCartForOverPayment() - Cart item added with remaining value (before = ' + newItem.adjustedValue + ', after = ' + newItem.perCard + ', qty = ' + newItem.amount + ')');
									}
								}
								else
								{
									item.perCard = item.adjustedValue + perCardToAdjust;
									totalAdjusted += perCardToAdjust * item.amount;
									cardsAdjusted += item.amount;
									trace ('CartModel::adjustCartForOverPayment() - Cart item adjusted (before = ' + item.adjustedValue + ', after = ' + item.perCard + ', qty = ' + item.amount + ')');
								}
							}
							else
							{
								item.perCard = item.adjustedValue; // host review will substract fees from total
								cardsAdjusted += item.amount;
							}

							if (cardsAdjusted >= adjustableCardsInCart)
							{
								trace ('CartModel::adjustCartForOverPayment() - final total = ' + totalAdjusted.toString() );
								if (totalAdjusted < totalToAdjust)
								{
									// add rounding to last card or split a card off
									if (item.amount == 1)
									{
										item.perCard = item.perCard + (totalToAdjust - totalAdjusted); // perCard has existing adjustment
										trace ('CartModel::adjustCartForOverPayment() - Cart item adjusted with final amount (before = ' + item.adjustedValue + ', after = ' + item.perCard + ', qty = ' + item.amount + ')');
									}
									else
									{
										applyUpdate ( item, { amount : item.amount-1 } );
										trace ('CartModel::adjustCartForOverPayment() - Cart item split with final amount (before = ' + item.adjustedValue + ', after = ' + item.perCard + ', qty = ' + item.amount + ')');
										newItem = copyCartItem(item);
										// adjust values
										newItem.amount = 1;
										newItem.perCard = item.perCard + (totalToAdjust - totalAdjusted); // perCard has existing adjustment
										addItem( newItem );
										trace ('CartModel::adjustCartForOverPayment() - Cart item added with final amount (before = ' + newItem.adjustedValue + ', after = ' + newItem.perCard + ', qty = ' + newItem.amount + ')');
									}
								}
							}
						}
					}
				}
			}
		}

		public function adjustCartForUnderPayment ( additionalCard : Object, newTotal : Number )
		{
			if ( totalCardsInCart == 1 && cartItems[0].card.allowUserValue )
			{
				cartItems[0].perCard = newTotal;
			}
			else
			{
				// replace cart with single card
				drain();
				var data : Object = { };
				data.card = additionalCard;
				data.amount = 1;
				data.perCard = newTotal;
				addItem( data );
			}
		}

		public function get cardTypeSelected ( ) : String
		{
			return _cardTypeSelected;
		}

		public function set cardTypeSelected ( cardType : String ) : void
		{
			_cardTypeSelected = cardType;
		}

		private function copyCartItem ( source : Object )
		{
			var destination : Object = {};
			for ( var i : String in source )
				destination[i] = source[i];
			return destination;
		}
	}
}
