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

	public class GeneratePinToken extends EventDispatcher implements IToken
	{
		protected var _response : *;
		protected var _seedData : *;

		protected var _data : URLVariables;
		protected var _loader : URLLoader;
		protected var _request : URLRequest;

		protected var timeoutTimer : Timer;

		public var mobile : Number;
		public var resetting : Boolean = false;

		public function GeneratePinToken ( )
		{
			timeoutTimer = new Timer (Environment.COMM_TIMEOUT * 1000);
			timeoutTimer.addEventListener ( TimerEvent.TIMER, onTimeout );

			super ( this );
		}

		public function start ( data : * = null ) : void
		{
			_seedData = data;

			if ( resetting )
			{
				_request = new URLRequest ( CardPrintingService.PAYMENT_ENDPOINT + "/api/accounts/reset_pin.xml" );
			}else
			{
				_request = new URLRequest ( CardPrintingService.PAYMENT_ENDPOINT + "/api/accounts/create.xml" );
			}

			_request.method = URLRequestMethod.POST;
			_request.data = new URLVariables();
			_request.data.mobile = data.mobile;

			if ( data.email ) _request.data.email = data.email;
			if ( data.preferredBank ) _request.data.preferred_bank = data.preferredBank;

			_loader = new URLLoader();
			_loader.addEventListener ( Event.COMPLETE, onDataResponse, false, 0, true );
			_loader.addEventListener ( IOErrorEvent.IO_ERROR, onDataError, false, 0, true );
			_loader.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onDataError, false, 0, true );
			timeoutTimer.reset();
			timeoutTimer.start();
			Logger.beginTimer( "Host Communication: Generate PIN" );
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
			dispatchEvent ( new TokenEvent ( TokenEvent.COMPLETE, response ) );
		}

		public function notifyError ( reason : String = "" ) : void
		{
			dispatchEvent ( new TokenEvent ( TokenEvent.ERROR, reason) );
		}
	}

}