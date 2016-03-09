package com.snepo.givv.cardbrowser.services.pinpad
{
	import com.snepo.givv.cardbrowser.managers.*;	
	import com.snepo.givv.cardbrowser.view.controls.*;	
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*

	import flash.events.*;
	import flash.net.*;

	public class PinPadService extends EventDispatcher
	{
		public static var HOST : String = Environment.SERVICE;
		public static var PORT : int = 2013;

		protected var _socket : Socket;
		protected var _loggedOn : Boolean = false;
		protected var doLogon : Boolean = true;

		public var amount : Number;
		public var txnID : String;

    	public function PinPadService( doLogon : Boolean = true )
		{
			super ( this );
			this.doLogon = doLogon;
		}

		public function connect ( ) : void
		{
			_socket = new Socket();
			_socket.addEventListener ( Event.CONNECT, handleConnect, false, 0, true );
			_socket.addEventListener ( IOErrorEvent.IO_ERROR, handleError, false, 0, true );
			_socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, handleError, false, 0, true );
			_socket.addEventListener ( ProgressEvent.SOCKET_DATA, readIncomingBuffer, false, 0, true );
			_socket.connect ( HOST, PORT );
		}

		protected function handleConnect ( evt : Event ) : void
		{
			trace ( "PinPadService connected...");

			if ( doLogon )
			{
				logon();
			}else
			{
				dispatchEvent ( new Event ( Event.CONNECT ) );
			}
		}

		protected function handleError ( evt : ErrorEvent ) : void
		{
			//View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( '151' ) ) );
			trace ( "PinPadService error -> " + evt.toString() );
			dispatchEvent ( new PinPadEvent(PinPadEvent.FAIL,new XML("<error>" + evt.text + "</error>")) );
		}

		protected function readIncomingBuffer ( evt : ProgressEvent ) : void
		{
			var buffer : String = _socket.readUTFBytes ( _socket.bytesAvailable );
			try
			{
				var packet : XML = new XML ( "<Wrapper>" + buffer + "</Wrapper>" );
				var messages : XMLList = packet..Message;

				for ( var i : int = 0; i < messages.length(); i++ )
				{
					var message : XML = messages[i];
					processMessage ( message );
				}


			}catch ( e : Error )
			{
				trace ( e.toString() );
				trace ( "Error parsing PinPadService packet: " + buffer );
			}

		}

		protected function processMessage ( message : XML ) : void
		{
			dispatchEvent ( new PinPadEvent ( message.@type.toString(), message  ) );

			trace ( "======");
			trace ( message.toXMLString() );
			trace ( "======");

			switch ( message.@type.toString() )
			{
				case PinPadEvent.LOGON :
				{
					if ( message.Success.text() == "1" )
					{
						trace ( "PinPadService is now logged on..." );
						_loggedOn = true;
					}
				}
			}
		}

		public function close ( ) : void
		{
			if ( _socket && _socket.connected )
			{
				_socket.removeEventListener ( Event.CONNECT, handleConnect );
				_socket.removeEventListener ( IOErrorEvent.IO_ERROR, handleConnect );
				_socket.removeEventListener ( SecurityErrorEvent.SECURITY_ERROR, handleError );
				_socket.removeEventListener ( ProgressEvent.SOCKET_DATA, readIncomingBuffer );
				_socket.close();
				_socket = null;
			}

			_loggedOn = false;
		}

		public function processTransaction ( transactionID : String, amount : Number ) : Boolean
		{
			//if ( !_loggedOn ) return false;

			send ( <Message type="Transaction" id="transactionCommand"><Account>1</Account><TxnType>Purchase</TxnType><TxnRef>{transactionID}</TxnRef><AmountPurchase>{amount}</AmountPurchase></Message>.toXMLString() );
			return true;
		}

		public function cancel ( ) : void
		{
			sendButtonCommand ( "Cancel", "transactionCommand" );
		}

		protected function logon ( ) : void
		{
			send ( <Message type="Logon" id="loginCommand"> <Account>1</Account></Message>.toXMLString() );
		}

		public function sendButtonCommand ( label : String, id : String = "1234" ) : void
		{
			var command : String = <Message type="Button" id={id}><Button>{label}</Button></Message>.toXMLString();
			send(command);
		}

		public function startCustomRead ( ) : void
		{
			var command : String = <Message type="ReadCard" id="customRead"><Text1>INSER CARD</Text1><Text2></Text2><EnableBackLight>1</EnableBackLight></Message>.toXMLString();
			send(command);
		}

		protected function send ( command : String ) : void
		{
			trace ("PinPadService::send() - " + command);
			if ( _socket && _socket.connected )
			{
				_socket.writeUTFBytes ( command );
				_socket.flush();
			}
		}

		public function get loggedOn ( ) : Boolean
		{
			return _loggedOn;
		}


	}

}