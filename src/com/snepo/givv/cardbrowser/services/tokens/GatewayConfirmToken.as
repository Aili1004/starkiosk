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

	public class GatewayConfirmToken extends EventDispatcher implements IToken
	{
		public static const MESSAGE_VERSION : int = 3;

		protected var _response : *;
		protected var _seedData : *;

		protected var _data : URLVariables;
		protected var _loader : URLLoader;
		protected var _request : URLRequest;

		protected var timeoutTimer : Timer;

		public function GatewayConfirmToken ( )
		{
			timeoutTimer = new Timer (Environment.COMM_TIMEOUT * 1000);
			timeoutTimer.addEventListener ( TimerEvent.TIMER, onTimeout );

			super ( this );
		}

		public function start ( data : * = null ) : void
		{
			this._seedData = <request>
													<messageVersion>{MESSAGE_VERSION}</messageVersion>
													<kioskuniqid>{Environment.KIOSK_UNIQUE_ID}</kioskuniqid>
													<password>{Model.getInstance().getPassword()}</password>
													<ribbonLevel>{data.ribbonLevel}</ribbonLevel>
													<card>
														<id>{data.cardID}</id>
														<number>{data.printerCardID}</number>
														<status>complete_printed</status>
													</card>
											 </request>;

			if ( CardPrintingService.LOG ) Logger.log ("GatewayConfirmToken::start" );

			_request = new URLRequest ( CardPrintingService.PAYMENT_ENDPOINT + "/api/cards/update.xml" );
			_request.method = URLRequestMethod.POST;
			_request.contentType = "text/xml";
			_request.data = this._seedData;
			trace ( "GatewayConfirm request:\n" + this._request.data );

			_loader = new URLLoader();
			_loader.addEventListener ( Event.COMPLETE, onDataResponse, false, 0, true );
			_loader.addEventListener ( IOErrorEvent.IO_ERROR, onDataError, false, 0, true );
			_loader.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onDataError, false, 0, true );
			timeoutTimer.reset();
			timeoutTimer.start();
			Logger.beginTimer( "Host Communication: CONFIRMATION" );
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
			if ( CardPrintingService.LOG ) Logger.log ( "GatewayConfirmToken::response" );
			this._response = new XML ( evt.target.data );

			trace ( "GatewayConfirm response:\n" + this._response );

			if ( this.response.error.children().length() > 0 )
			{
				notifyError( this.response.error.code.text() );
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
			if ( CardPrintingService.LOG ) Logger.log ("CheckscannableToken::notifyTimeout");
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

		public function notifyComplete ( ) : void
		{
			if ( CardPrintingService.LOG ) Logger.log ("GatewayConfirmToken::notifyComplete");
			dispatchEvent ( new TokenEvent ( TokenEvent.COMPLETE, response ) );
		}

		public function notifyError ( reason : String = "" ) : void
		{
			if ( CardPrintingService.LOG ) Logger.log ("GatewayConfirmToken::notifyError");
			dispatchEvent ( new TokenEvent ( TokenEvent.ERROR, reason ) )
		}
	}

}