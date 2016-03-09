package com.snepo.givv.cardbrowser.model
{
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class HostModel extends EventDispatcher
	{
		public static const KIOSK_TYPE_ALL : String = "all_features";
		public static const KIOSK_TYPE_NOCOIN : String = "no_coin";
		public static const KIOSK_TYPE_COINONLY : String = "coin_only";

		public static const CARD_STOCK_PREPRINTED_BACK : String = "preprinted_back";
		public static const CARD_STOCK_PREPRINTED : String = "preprinted";
		public static const CARD_STOCK_BLANK : String = "blank";
		public static const CARD_STOCK_DO_NOT_PRINT : String = "do_not_print";

		public static const BUTTON_HOME_PRIMARY_ID : int   = 1;
		public static const BUTTON_HOME_SECONDARY_ID : int = 2;
		public static const BUTTON_HOME_TERTIARY_ID : int  = 3;
		public static const BUTTON_HOME_COUNT	: int 			 = 3;
		public static const BUTTON_BALANCE_ID : int  			 = 1000;

		public static const TXN_FEE_TYPE_VISA : String = 'visa';
		public static const TXN_FEE_TYPE_MASTERCARD : String = 'master';
		public static const TXN_FEE_TYPE_AMEX : String = 'american_express';

		public static const UI_OPTIONS_WOOLWORTHS_CAPTURE_EDR : int = 1;

		public static const REMOTE_CONTROL_RESTART_UI = 'restart_ui';
		public static const REMOTE_CONTROL_UPGRADE_NOW = 'upgrade_now';
		public static const REMOTE_CONTROL_UPGRADE_OVERNIGHT = 'upgrade_overnight';
		public static const REMOTE_CONTROL_DOWNGRADE_NOW = 'downgrade_now';
		public static const REMOTE_CONTROL_DOWNGRADE_OVERNIGHT = 'downgrade_overnight';

		public static const PAYMENT_OPTION_DISABLE_NOTES = 'disable_note_payments';
		public static const PAYMENT_OPTION_DISABLE_CARDS = 'disable_card_payments';

		protected var _displayName : String = "";
		protected var _hostName : String = "";
		protected var _kioskType : String = "";
		protected var _minCartValue : Number;
		protected var _maxCartValue : Number;
		protected var _maxCartCards : int;
		protected var _maxCardValue : Number;
		protected var _customerMobile : String = "";
		protected var _customerPin : String = "";
		protected var _disableAmex : Boolean;
		protected var _paymentOption : String = "";
		protected var _disableCoins : Boolean;
		protected var _disableCoinsReason : String = "";
		protected var _cardStock : String = "";
		protected var _loyaltyTitle : String = "";
		protected var _loyaltyEndpoint : String = "";
		protected var _loyaltyCardRangeStart : int;
		protected var _loyaltyCardRangeEnd : int;
		protected var _backgroundImage : String = "";
		protected var _uiOptions : int = 0;
		protected var _receiptText : String = "";
		protected var _receiptErrorText : String = "";
		protected var _coinTerms : String = "";
		protected var _transactionReferenceText : String = "";
		protected var _outOfOrderMessage : String = "";
		protected var _buttons : Object = {};
		protected var _visibleHomeButtonCount : int;
		protected var _buttonsByPosition : Array = new Array(BUTTON_HOME_COUNT);
		protected var _products : Array = [];
		protected var _productIDs : Array = [];
		protected var _primaryProducts : Array = [];
		protected var _categories : Array = [];
		protected var _transactionFees : Object = {};
		protected var _hasCardSurcharge : Boolean = false;
		protected var _hasHost : Boolean = false;
		public var remoteControl : String = "";

    public function HostModel()
		{
			super ( this );
		}

		public function populate ( data : XML ) : void
		{
		 	var r:RegExp = /\r/g;
			_displayName = data.kiosk.display_name.text();
			_kioskType = data.kiosk.kioskType.text();
			_minCartValue = Number(data.kiosk.cartLimits.minValue.text());
			_maxCartValue = Number(data.kiosk.cartLimits.maxValue.text());
			_maxCartCards = int(data.kiosk.cartLimits.maxCards.text());
			_maxCardValue = Number(data.kiosk.cartLimits.maxCardValue.text());
			_customerMobile = data.kiosk.customer.mobile.text();
			_customerPin = data.kiosk.customer.pin.text();
			_disableAmex = data.kiosk.disableAmex.text() == 'true';
			_paymentOption = data.kiosk.paymentOption.text();
			_disableCoins = data.kiosk.disableCoins.text() == 'true';
			_disableCoinsReason = data.kiosk.disableCoinsReason.text();
			_cardStock = data.kiosk.cardStock.text();
			_loyaltyTitle = data.kiosk.loyalty.title.text();
			_loyaltyEndpoint = data.kiosk.loyalty.endpoint.text();
			_loyaltyCardRangeStart = int(data.kiosk.loyalty.cardRangeStart.text());
			_loyaltyCardRangeEnd = int(data.kiosk.loyalty.cardRangeEnd.text());
			_hostName = data.kiosk.host.name.text();

			// KIOSK PROFILE
			_backgroundImage = data.kiosk.profile.backgroundImage.text();
			_uiOptions = int(data.kiosk.profile.options.text());
			_receiptText = (data.kiosk.profile.receiptText.text() + "").replace(r,'');
			_receiptErrorText = (data.kiosk.profile.receiptErrorText.text() + "").replace(r,'');
			_coinTerms = (data.kiosk.profile.coinTerms.text() + "").replace(r,'');
			_transactionReferenceText = (data.kiosk.profile.transactionReferenceText.text() + "").replace(r,'');
			_outOfOrderMessage = (data.kiosk.profile.outOfOrderMessage.text() + "").replace(r,'');

			// HOME BUTTONS
			var id : int;
			var position : int;
			var enabled : Boolean;
			var name : String;
			var title : String;
			var description : String;
			var footer : String;
			var category : int;
			var buttonList : XMLList = data.kiosk.host.buttons.children();
			_visibleHomeButtonCount = 0;
			for ( var i = 0; i < buttonList.length(); i++ )
			{
				var button : XML = buttonList[i];
				id = button.@id;
				position = int(button.position.text());
				enabled = button.enabled.text() == 'true';
				name = button.name.text();
				title = (button.title.text() + "").replace(r,'');
				description = (button.description.text() + "").replace(r,'');
				footer = (button.footer.text() + "").replace(r,'');
				category = int((button.categoryId.text() +"").replace(r,''));
				// Override button visibility based on kiosk type
				if (id == BUTTON_HOME_TERTIARY_ID && category <= 0)
				{
					if (_kioskType == HostModel.KIOSK_TYPE_NOCOIN)
						enabled = false;
					if (_disableCoins)
						description = "CURRENTLY UNAVAILABLE";
				}
				if (_kioskType == HostModel.KIOSK_TYPE_COINONLY )
				{
					if (id != BUTTON_HOME_TERTIARY_ID && id != BUTTON_BALANCE_ID)
						enabled = false;
					if (id == BUTTON_HOME_TERTIARY_ID)
					{
						enabled = true
						category = -1
					}
				}
				// Create button settings object using the first word of the button name
				_buttons[StringUtil.firstWord(name.toLowerCase())+""] =
				{
					id : id,
					position : position,
					enabled : enabled,
					name : name,
					title : title,
					description : description,
					footer : footer,
					category : category
				};
				// Update home button stats
				if (id < 1000 && enabled)
				{
					_buttonsByPosition[position] = _buttons[StringUtil.firstWord(name.toLowerCase())+""];
					_visibleHomeButtonCount++;
				}
			}

			var pList : XMLList = data..product;
			var order : int;
			for ( i = 0; i < pList.length(); i++ )
			{
				var prod : XML = pList[i];
				id = prod.@id;
				var primary : int = prod.@primary || 0;
				order = prod.@order || -1;

				_products.push ( { id : id, primary : primary, order : order } );
				_productIDs.push ( id );
				if ( primary > 0 ) _primaryProducts.push ( {id : id, primary : primary} );
			}
			_primaryProducts.sort ( orderByPrimary );

			var cList : XMLList = data..category;
			for ( i = 0; i < cList.length(); i++ )
			{
				var cat : XML = cList[i];
				id = cat.@id;
				order = cat.@order || -1;

				_categories.push ( {id : id, order : order} );
			}

			var feeType : String;
			var percentage : Number;
			var fee : XML;
			var feeList : XMLList = data.kiosk.host.transactionFees.children();
			for ( i = 0; i < feeList.length(); i++ )
			{
				fee = feeList[i];
				feeType = fee.feeType.text();
				description = fee.name.text();
				percentage = Number ( fee.percentage.text() ) || 0;
				_transactionFees[feeType+""] =
				{
					description : description,
					percentage : percentage
				};
				trace ("FEE = " + description + ' ' + percentage);
				if (percentage > 0 && (feeType != TXN_FEE_TYPE_AMEX || !_disableAmex))
				{
					trace ("has Surcharge");
					_hasCardSurcharge = true;
				};
			}

			_hasHost = data.kiosk.host.length() > 0;
		}

		function orderByPrimary(a, b):int
		{
		    if (Number(a.primary) < Number(b.primary))
		    {
		        return -1;
		    }
		    else if (Number(a.primary) > Number(b.primary))
		    {
		        return 1;
		    }
		    else
		    {
		        return 0;
		    }
		}

		public function filterProductsToHost ( list : XMLList ) : XMLList
		{

			var output : XML = <response/>

			for ( var i : int = 0; i < _productIDs.length; i++ )
			{
				var product : XMLList = list.(@id==_productIDs[i]);
				if ( product.length() > 0 )
					output.appendChild ( product[0] );
			}

			list = output..product;

			return list;
		}

		public function orderCategories ( list : XMLList ) : void
		{
			for ( var i : int = 0; i < _categories.length; i++ )
			{
				var category : XMLList = list.(@id==_categories[i].id);
				if ( category.length() > 0 )
					category.index = _categories[i].order;
			}
		}

		public function get hasHost ( ) : Boolean
		{
			return _hasHost;
		}

		public function get displayName ( ) : String
		{
			return _displayName;
		}

		public function get kioskType ( ) : String
		{
			return _kioskType;
		}

		public function get minCartValue ( ) : Number
		{
			return _minCartValue;
		}

		public function get maxCartValue ( ) : Number
		{
			return _maxCartValue;
		}

		public function get maxCartCards ( ) : Number
		{
			return _maxCartCards;
		}

		public function get maxCardValue ( ) : Number
		{
			return _maxCardValue;
		}

		public function get customerMobile ( ) : String
		{
			return _customerMobile;
		}

		public function get customerPin ( ) : String
		{
			return _customerPin;
		}

		public function get disableAmex ( ) : Boolean
		{
			return _disableAmex;
		}

		public function get paymentOption ( ) : String
		{
			return _paymentOption;
		}

		public function get disableCoins ( ) : Boolean
		{
			return _disableCoins;
		}

		public function get disableCoinsReason ( ) : String
		{
			return _disableCoinsReason;
		}

		public function get cardStock ( ) : String
		{
			return _cardStock;
		}

		public function get loyaltyTitle ( ) : String
		{
			return _loyaltyTitle;
		}

		public function get loyaltyEndpoint ( ) : String
		{
			return _loyaltyEndpoint;
		}

		public function get loyaltyCardRangeStart ( ) : int
		{
			return _loyaltyCardRangeStart;
		}

		public function get loyaltyCardRangeEnd ( ) : int
		{
			return _loyaltyCardRangeEnd;
		}

		public function get backgroundImage ( ) : String
		{
			return _backgroundImage;
		}

		public function get uiOptions ( ) : int
		{
			return _uiOptions;
		}

		public function get receiptText ( ) : String
		{
			return _receiptText;
		}

		public function get receiptErrorText ( ) : String
		{
			return _receiptErrorText;
		}

		public function get coinTerms ( ) : String
		{
			return _coinTerms;
		}

		public function get transactionReferenceText ( ) : String
		{
			return _transactionReferenceText;
		}

		public function get outOfOrderMessage ( ): String
		{
			return _outOfOrderMessage;
		}

		public function get buttons ( ) : Object
		{
			return _buttons;
		}

		public function get visibleHomeButtonCount ( ) : int
		{
			return _visibleHomeButtonCount;
		}

		public function getHomeButtonByPosition ( position : int ) : Object
		{
			return _buttonsByPosition[position];
		}

		public function get products ( ) : Array
		{
			return _products;
		}

		public function get primaryProducts ( ) : Array
		{
			return _primaryProducts;
		}

		public function get transactionFees ( ) : Object
		{
			return _transactionFees;
		}

		public function get hasCardSurcharge ( ) : Boolean
		{
			return _hasCardSurcharge;
		}

		public function get hostName ( ) : String
		{
			return _hostName;
		}

		public function get printTime ( ) : int
		{
			switch (cardStock)
			{
				case CARD_STOCK_PREPRINTED:
					return 8;
				case CARD_STOCK_DO_NOT_PRINT:
					return 0.5;
				default:
					return 30;
			}
		}
	}

}