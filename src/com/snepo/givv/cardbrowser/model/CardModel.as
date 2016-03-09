package com.snepo.givv.cardbrowser.model
{
	import com.snepo.givv.cardbrowser.view.core.ImageCache;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class CardModel extends EventDispatcher
	{

		public static const PRINTABLE : String = "printable";
		public static const SCANNABLE : String = "scannable";
		public static const VIRTUAL   : String = "virtual";

		public static const BLACKHAWK : String = 'blackhawk';

		public static const PRIMARY_CARD_1 : int = 1
		public static const PRIMARY_CARD_2 : int = 2
		public static const SECONDARY_CARD_1 : int = 3
		public static const SECONDARY_CARD_2 : int = 4
		public static const EXCHANGE_CARD : int = 5
		public static const TERTIARY_CARD_1 : int = 6
		public static const TERTIARY_CARD_2 : int = 7

		protected var _cards : Array = [];
		protected var _selectedCard : Object;

		public var cardIDMap : Dictionary = new Dictionary();
		public var currentScanData : Object;

		protected var _nonScannableCards : Array = [];
		protected var _charityCards : Array = [];

		public function CardModel()
		{
			super( this );
		}

		public function set selectedCard ( c : Object ) : void
		{
			if ( c == selectedCard ) return;

			this._selectedCard = c;

			dispatchEvent ( new CardEvent ( CardEvent.SELECTED_CARD_CHANGED ) );
		}

		public function injectImagesIntoCache ( ) : void
		{
			var cache : ImageCache = ImageCache.getInstance();

			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				cache.add ( ImageCache.ICON, card.id, card.images.icon );
				cache.add ( ImageCache.THUMB, card.id, card.images.thumb );
				cache.add ( ImageCache.IMAGE, card.id, card.images.screen );

			}

		}

		public function getPrintURL ( productID : String ) : String
		{
			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( ( card.id + "" ) == productID )
				{
					return (Environment.isDevelopment ? Model.DROPBOX_DEV_PATH : Model.DROPBOX_PATH) + card.images.print.replace(/\//g, "\\" );
				}
			}

			return "";
		}

		public function lookupScannableCard ( upc : String ) : Object
		{
			trace ( "looking up scannable card: " + upc )
			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( card.matchpattern != null )
				{
					var doesMatch : Boolean = card.matchpattern.test ( upc );
					if ( doesMatch )
					{
						trace("lookupScannableCard - found match on pattern")
						return card;
					}
				}else if ( card.upc != null )
				{
					if ( card.upc != null && card.upc == upc )
					{
						trace("lookupScannableCard - found match on upc:" + card.upc)
						return card;
					}
				}
			}
			trace ("lookupScannableCard - card not found")
			return null;
		}

		public function get selectedCard ( ) : Object
		{
			return this._selectedCard;
		}

		public function hostPrimaryProducts (primaryIds : Array) : Array
		{
			var output : Array = [];
			var primaryProducts : Array = Model.getInstance().host.primaryProducts;

			var j : int;
			for ( var i : int = 0; i < primaryIds.length; i++ )
			{
				for ( j = 0; j < primaryProducts.length; j++ )
				{
					if (primaryIds[i] == primaryProducts[j].primary )
					{
						var product : Object = getCardByID ( primaryProducts[j].id + "" );
						if ( product.name != "Unknown card" ) output.push ( product );
					}
				}
			}

			return output;
		}

		public function populate ( source : XML ) : void
		{
			var list : XMLList = source..product;

			var host : HostModel = Model.getInstance().host;

			if ( host.hasHost )
			{
				list = host.filterProductsToHost ( list );
			}

			var products : Array = [];
			var i : int, j : int;

			for ( i = 0; i < list.length(); i++ )
			{
				var item : XML = list[i];
				var id : int = item.@id;
				var active : Boolean = item.@active == "true";
				var bits : int = int(item.categorybits.text());
				var api : String = item.api.text() + "";
				var priority : int = int(item.priority.text());
				var processas : String = item.processas.text() + "";
				var upc : String = item.upc.text() + "";
				var partnerID : String = item.partner_id.text() + "";
				var name : String = item.name.text();
				var description : String = item.description.text();
				var matchpattern : RegExp = null;
				if ( item.matchpattern.text().length() > 0 )
				{
					matchpattern = new RegExp ( item.matchpattern.text() /*, "g"*/ );
				}else
				{
					matchpattern = null;
				}

				var allowUserValue : Boolean = item.allowuservalue.text() == "true";
				var minValue : Number = item.minValue.text().length() > 0 ? Number ( item.minValue.text() ) : -1;
				var maxValue : Number = item.maxValue.text().length() > 0 ? Number ( item.maxValue.text() ) : -1;

				var denominations : Array = [];
				var denomsList : XMLList = item.denominations..denomination;

				for ( j = 0; j < denomsList.length(); j++ )
				{
					var denomID : int = denomsList[j].@id;
					var denomPromo : Boolean = denomsList[j].@promotion == "true";
					var value : Number = Number ( denomsList[j].value.text() );
					var price : Number = Number ( denomsList[j].price.text() );

					var isDefault : Boolean = denomsList[j].@default == "true";
					if ( isNaN ( price ) || price == 0 ) price = value;
					var label : String = StringUtil.currencyLabelFunction ( price );

					denominations.push ( { id : denomID, promotion : denomPromo, isDefault : isDefault, value : value, price : price, label : label } );

				}

				denominations.sortOn ( "value", Array.DESCENDING | Array.NUMERIC );
				denominations.reverse();

				if ( allowUserValue ) denominations.push( { id : denomID, promotion : false, isDefault : false, value : "+", label : "Enter Value...", enabled : true } );

				var images : Object = { };
				var imageList : XMLList = item.graphics.children();

				for ( j = 0; j < imageList.length(); j++ )
				{
					var imagePath : String = imageList[j].text();
					if ( imagePath.charAt(0) == "/" ) imagePath = "assets" + imagePath;
					images [ imageList[j].name() + "" ] = imagePath;
				}
				var backID : int = item.back_design_id;

				products.push ( { id : id, active : active, categoryBits : bits, api : api, partnerID : partnerID, priority : priority, name : name,
					                matchpattern : matchpattern, description : description, upc : upc, processas : processas, denominations : denominations,
					                allowUserValue : allowUserValue, minValue : minValue, maxValue : maxValue,
					                images : images, backID : backID } );

			}

			this._cards = products;

			injectImagesIntoCache();
		}

		public function isEmptyCategory ( categoryFlag : int ) : Boolean
		{
			for ( var i : int = 0; i < nonScannableCards.length; i++ )
			{
				var card : Object = nonScannableCards[i];
				var flag : int = card.categoryBits;

				if ( BitUtil.match ( categoryFlag, flag ) ) return false;
			}

			return true;
		}

		public function loadStub ( path : String ) : void
		{
			return;
			var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, parseStub );
				loader.load ( new URLRequest ( path ) );
		}

		protected function parseStub ( evt : Event ) : void
		{
			var source : XML = new XML ( evt.target.data );
			var cards : XMLList = source..card;

			for ( var i : int = 0; i < cards.length(); i++ )
			{
				var card : XML = cards[i];
				var cardObj : Object = {};

				var elements : XMLList = card.children();

				for ( var j : int = 0; j < elements.length(); j++ )
				{
					var element : XML = elements[j];
					cardObj [ element.name() ] = element.text();
				}

				_cards.push ( cardObj );

			}

			dispatchEvent ( new Event ( Event.COMPLETE ) );
		}

		public function getCardByID ( id : String ) : Object
		{
			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( ( card.id + "" ) == id ) return card;
			}

			return { name : "Unknown Card" };
		}

		public function get randomCard ( ) : Object
		{
			return _cards [ Math.floor ( Math.random() * _cards.length ) ];
		}

		public function get cards () : Array
		{
			return _cards;
		}

		public function get nonScannableCards ( ) : Array
		{
			if ( _nonScannableCards.length ) return _nonScannableCards;

			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( card.api == "charity" )
				{
					for ( var s : String in card )
					{
						trace ( s + " : " + card[s] );
					}
				}

				_nonScannableCards.push ( card );
			}

			return _nonScannableCards;
		}

		public function get charityCards ( ) : Array
		{
			if ( _charityCards.length ) return _charityCards;

			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( card.api == "charity" ) _charityCards.push ( card );

			}

			return _charityCards;
		}


		public function getCardsByType ( type : String ) : Array
		{
			var out : Array = [];

			for ( var i : int = 0; i < cards.length; i++ )
			{
				var card : Object = cards[i];
				if ( card.processas == type ) out.push ( card );
				out.push ( card );
			}

			return out;
		}

	}
}