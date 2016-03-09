package com.snepo.givv.cardbrowser.util
{
	public class CreditCardUtil
	{

		public static const AMERICAN_EXPRESS : String = "american_express";
		public static const MASTER_CARD : String = "master";
		public static const DISCOVER : String = "discover";
		public static const UNKNOWN : String = "unknown";
		public static const VISA : String = "visa";

		public static function luhnValidate ( cardNumber : String ) : Boolean
		{
			var cardCheck:Array = [];
			var i:int = 0;
			var sum:int = 0;
			
			for ( i = 0; i < cardNumber.length; ++i )
			{
				cardCheck[i] = Number ( cardNumber.charAt(i) );
			}
			
			for ( i = cardCheck.length - 2; i >= 0; i -= 2 )
			{
				cardCheck[i] *= 2;
				if ( cardCheck[i] > 9 ) cardCheck[i] -= 9;
			}
			
			for ( i = 0; i < cardCheck.length; ++ i )
			{
				sum += cardCheck[i];
			}
			
			return sum % 10 == 0;
		}

		public static function processTrack ( card : String ) : Object
		{
			var nameParts : Array = card.match(/\^([a-zA-Z0-9\/\. ]+)\^/);
			var cardParts : Array = card.match(/([0-9]{15,16})=([0-9]{4})/ );
			
			var response : Object = {};
				response.isValid = false;
							
			if ( cardParts && cardParts.length > 2 )
			{
				var cardNumber : String = cardParts[1];
				var isValidCard : Boolean = CreditCardUtil.isCreditCard( cardNumber );
				
				if ( !isValidCard )
				{
					response.isValid = false;
					return response;
				}

				if ( nameParts && nameParts.length > 0 )
				{
					var nameRef : String = StringUtil.trimRight( nameParts[1] );
						response.name = nameRef;
				}else
				{
					
					var prov : String = CreditCardUtil.getCardProvider( cardNumber );
					if ( !prov || prov == "unknown" )
					{
						response.isValid = false;
						return response;
					}else
					{
						response.name = prov + " Pre Paid";
					}
				}
				
				var expiryYear : String = "20" + cardParts[2].substring ( 0, 2 );
				var expiryMonth : String = cardParts[2].substring ( 2, 4 );
				
				response.isValid = true;
				response.card = cardNumber;
				response.provider = CreditCardUtil.getCardProvider( cardNumber );
				response.year = expiryYear;
				response.month = expiryMonth;

				if ( Environment.DEBUG )
				{
					response.card = "4444333322221111";
					response.provider = VISA;
					response.year = 2014;
					response.month = 10;
				}
			}
			
			return response;
		}

		protected static function parseName ( name : String ) : Object
		{
			var firstName : String = "";
			var lastName : String = "";
			
			var response : Object = { isValid : false };
			
			var spaceSeparated : Array = name.split(" ");
			
			if ( spaceSeparated.length > 1 )
			{
				var halfSize : int = spaceSeparated.length / 2;
				for ( var i : int = 0; i < spaceSeparated.length; i++ )
				{
					if ( i < halfSize )
					{
						firstName += spaceSeparated[i] + " ";
					}else
					{
						lastName += spaceSeparated[i] + " ";
					}
					
					response.firstName = firstName;
					response.lastName = lastName;
					response.isValid = true;
				}
			
			}else
			{
				var slashParts : Array = name.split("/");
				if ( slashParts.length > 1 )
				{
					response.isValid = true;
					response.firstName = slashParts[1].split(".")[0];
					response.lastName = slashParts[0].split(".")[0];
				}
			}
			
			return response;
		}

		public static function isCreditCard ( card : String ) : Boolean
		{
			return luhnValidate ( card );
		}

		public static function getCardProvider ( card : String ) : String
		{
			var card4 : String = card.substring ( 0, 4 );
			var card3 : String = card.substring ( 0, 3 );
			var card2 : String = card.substring ( 0, 2 );
			var card1 : String = card.substring ( 0, 1 );

			if ( card4 == "6011" ) return DISCOVER;
			if ( card2 == "34" || card2 == "37" ) return AMERICAN_EXPRESS;
			if ( card1 == "5" ) return MASTER_CARD;
			if ( card1 == "4" ) return VISA;

			return UNKNOWN;
		}
	}
}