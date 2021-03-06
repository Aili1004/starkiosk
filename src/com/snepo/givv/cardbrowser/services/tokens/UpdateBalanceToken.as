package com.snepo.givv.cardbrowser.services.tokens
{
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;

	public class UpdateBalanceToken extends EventDispatcher implements IToken
	{
		public static const MESSAGE_VERSION : int = 4;

		public static const COIN : String = "coin";
		public static const CARD : String = "card";
		public static const NOTES : String = "note";

		protected var _response : *;
		protected var _seedData : *;

		protected var _data : URLVariables;
		protected var _loader : URLLoader;
		protected var _request : URLRequest;

		public var mobile : Number;
		protected var timeoutTimer : Timer;
		protected var model : Model = null;


		public function UpdateBalanceToken ( )
		{
			timeoutTimer = new Timer (Environment.COMM_TIMEOUT * 1000);
			timeoutTimer.addEventListener ( TimerEvent.TIMER, onTimeout );
			model = Model.getInstance();

			super ( this );
		}

		public function start ( data : * = null ) : void
		{
			_seedData = <request>
										<messageVersion>{MESSAGE_VERSION}</messageVersion>
										<kioskuniqid>{Environment.KIOSK_UNIQUE_ID}</kioskuniqid>
										<password>{Model.getInstance().getPassword()}</password>
										<paymentMethod>{model.cart.hostPaymentMethod}</paymentMethod>
										<total>{data.total}</total>
									</request>;
			var denominationsNode : XML = <denominations/>
			if (data.denominations != null)
			{
				for (var i : int = 0; i < data.denominations.length; i++)
					denominationsNode.appendChild(<denomination><value>{data.denominations[i].value}</value><quantity>{data.denominations[i].quantity}</quantity></denomination>);
			}
			_seedData.appendChild(denominationsNode);

			_request = new URLRequest ( CardPrintingService.PAYMENT_ENDPOINT + "/api/" + model.user.token + "/accounts/update_balance.xml" );
			_request.method = URLRequestMethod.POST;
			_request.contentType = "text/xml";
			_request.data = _seedData;

			trace ( "UpdateBalance request:\n" + this._request.data );

			_loader = new URLLoader();
			_loader.addEventListener ( Event.COMPLETE, onDataResponse, false, 0, true );
			_loader.addEventListener ( IOErrorEvent.IO_ERROR, onDataError, false, 0, true );
			_loader.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onDataError, false, 0, true );
			timeoutTimer.reset();
			timeoutTimer.start();
			Logger.beginTimer( "Host Communication: UPDATE CUSTOMER BALANCE" );
			_loader.load ( _request );
		}

		protected function removeEventListeners( ) : void
		{
			_loader.removeEventListener( Event.COMPLETE, onDataResponse );
			_loader.removeEventListener( IOErrorEvent.IO_ERROR, onDataError );
			_loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onDataError );
		}

		protected function onDataResponse ( evt : Event ) : void
		{
			Logger.endTimer("");
			timeoutTimer.reset();
			this._response = new XML ( evt.target.data );

			trace ( "UpdateBalance response:\n" + this._response );

			if ( this.response.error.children().length() > 0 )
			{
				if ( this.response.error.code.children().length() > 0 )
				{
					notifyError( this.response.error.code.text() );
				}else
				{
					notifyError ( this.response.error.text() );
				}

			}else
			{
				notifyComplete();
			}
		}

		public function dispose ( ) : void
		{

		}

		protected function onDataError ( evt : ErrorEvent ) : void
		{
			Logger.endTimer("");
			timeoutTimer.reset();
			notifyError ( evt.text + " : " + evt.target.data );
		}

		protected function onTimeout ( evt : TimerEvent ) : void
		{
			Logger.endTimer("");
			timeoutTimer.reset();
			removeEventListeners();
			notifyError ('157');
		}

		public function get status ( ) : Object
		{
			return { };
		}

		public function get response ( ) : *
		{
			return _response;
		}

		public function get seedData ( ) : *
		{
			return _seedData;
		}

		public function notifyComplete ( ) : void
		{
			dispatchEvent ( new TokenEvent ( TokenEvent.COMPLETE, response ) );
		}

		public function notifyError ( reason : String = "" ) : void
		{
			dispatchEvent ( new TokenEvent ( TokenEvent.ERROR, reason) );
		}
	}

}