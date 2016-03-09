package com.snepo.givv.cardbrowser.model
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import flash.events.*;
	import flash.utils.*;
	
	public class UserModel extends EventDispatcher
	{
		public static const CARD_TOKEN : String = "91e1b6aa6ce986500b1c2800fec04de74f4ddb19";

		protected var _mobile : String;
		protected var _id : int;

		protected var _balance : Number = 0;
		protected var _coinBalance : Number = 0;
		protected var _noteBalance : Number = 0;
		protected var _cardBalance : Number = 0;
		protected var _hasUser : Boolean = false;
		protected var _email : String = "";
		protected var _preferredBank : String = "";

		protected var _token : String;

		public function UserModel()
		{
			super ( this );
		}

		public function set loginData ( d : XML ) : void
		{
			if ( d != null )
			{
				_id = Number ( d.id.text() );
				_mobile = d.mobile.text();
				_token = d.token.text();
				_email = d.email.text() || "";
				_preferredBank = d.preferred_bank.text() || "";
				
				_hasUser = true;
			
				applyBalances ( d );

				trace ( "User is " + this.toString() );
				
				dispatchEvent ( new UserEvent ( UserEvent.JOINED ) );
			}else
			{
				_hasUser = false;
				dispatchEvent ( new UserEvent ( UserEvent.LEFT ) );
			}

		}

		public function applyBalances ( d : XML ) : void
		{
			_coinBalance = Number ( d.coin_amount.text() ) || 0;
			_noteBalance = Number ( d.note_amount.text() ) || 0;
			_cardBalance = Number ( d.card_amount.text() ) || 0;

			balance = _coinBalance + _noteBalance + _cardBalance;

		}

		public function set balance ( b : Number ) : void
		{
			_balance = b;

			dispatchEvent ( new UserEvent ( UserEvent.BALANCE_CHANGED ) );
		}

		public function clearUser ( ) : void
		{
			_hasUser = false;
			_mobile = "";
			
			_coinBalance = _noteBalance = _cardBalance = 0;
			_token = "";
			_id = -1;
			_preferredBank = "";
			_email = "";

			dispatchEvent ( new UserEvent ( UserEvent.LEFT ) );
		}

		public function get mobile  ( ) : String { return _mobile; }
		public function get token ( ) : String { return _token }; //return Model.getInstance().cart.paymentMethod == CartModel.CARDS ? CARD_TOKEN : _token
		public function get hasUser ( ) : Boolean { return _hasUser };
		public function get balance ( ) : Number { return _coinBalance + _cardBalance + _noteBalance; }
		public function get coinBalance ( ) : Number { return _coinBalance };
		public function get cardBalance ( ) : Number { return _cardBalance };
		public function get noteBalance ( ) : Number { return _noteBalance };
		public function get preferredBank ( ) : String { return _preferredBank };
		public function get email () : String { return _email; };
		
		public function get applicableBalance ( ) : Number
		{
			switch ( Model.getInstance().cart.paymentMethod )
			{
				case CartModel.CARDS :
				{
					return cardBalance;
				}

				case CartModel.NOTES :
				{
					return noteBalance;
				}

				case CartModel.COINS :
				{
					return coinBalance;
				}
			}

			return 0;
		}

		override public function toString ( ) : String
		{
			var message : String = "[User(";
			var params : Array = [ "mobile", "token", "preferredBank", "email", "coinBalance", "cardBalance", "noteBalance" ];

			for ( var i : String in params ) 
			{
				message += "'" + params[i] + "'='" + this[params[i]] + "',";
			}

			message = message.substring ( 0, message.length - 1 ) + ")]";
			return message;

		}

	}
}