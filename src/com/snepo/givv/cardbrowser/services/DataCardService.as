package com.snepo.givv.cardbrowser.services
{

	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.*;

	import com.adobe.serialization.json.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class DataCardService extends EventDispatcher
	{
		public static const HOST : String = Environment.SERVICE; //"192.168.1.125";
		public static const PORT : int = 2012;

		protected var socket : Socket;

		protected var _state : int;
		protected var _isPrinting : Boolean = false;
		protected var _lastError : Object;
		protected var _lastData : Object = {};

		protected var ready : Boolean = false;

		// store printing parameters for retry
		protected var _path : String;
		protected var _issueDate : String;
		protected var _value : String;
		protected var _cardStock : String;
		protected var _back : Object;
		protected var _cardData : XML;

		public function DataCardService()
		{
			super(this);
		}

		protected function reset ( )
		{
			_state = -1;
			_isPrinting = false;
			_lastError = null;

			_path = null;
			_issueDate = null;
			_value = null;
			_cardStock = null;
			_back = null;
			_cardData = null;
		}

		public function printCard ( imagePath : String, issueDate : String, value : String, backId : int, cardData : XML ) : void
		{
			if ( isPrinting ) return;

			reset();

			_path = imagePath;
			_issueDate = issueDate;
			_value = value;
			_cardStock = Model.getInstance().host.cardStock;
			_back = Model.getInstance().backs.getBackByID(backId);
			_cardData = cardData;
			if (_back.id == -1)
			{
				// TODO set values if back is not found
				_back = { name : 'Unknown', images : {} };
			}
			trace ("DataCardServuce::printCard() - Using back image: " + _back.name);

			retry();
		}

		public function printCardFinalisation ( cardData : XML ) : void
		{
			if ( !isPrinting ) return;

			_cardData = (cardData != null ? cardData : new XML);
			trace ("DataCardServuce::printCardFinalisation() - cardData:" + (cardData == null ? "" : cardData.toString()));

			retry(true);
		}

		public function retry ( printFinalisation : Boolean = false ) : void
		{
			_isPrinting = true;

			var command : String = "<command><call>Print" + (printFinalisation ? "_Finalisation" : "") + "</call>"
			// card stock type
			if (Environment.DEBUG && ConfigManager.get("dev") != null && ConfigManager.get("dev").doNotPrint == "true")
				command = command + "<doNotPrint>true</doNotPrint>";
			command = command + "<cardStock><![CDATA[" + _cardStock + "]]></cardStock>";
			// Front of card
			command = command + "<front>"
			command = command + "<path><![CDATA[" + _path + "]]></path>";
			command = command + "</front>"
			// Back of card
			command = command + "<back>"
  		// image
			if (_back.images.hasOwnProperty("print") &&  _back.images.print.toString().length > 0)
				command = command + "<path><![CDATA[" + Model.getInstance().backs.getPrintURL(_back.id) + "]]></path>";
			// Card Data
			if (_cardStock == HostModel.CARD_STOCK_BLANK && _cardData != null)
			{
				// card id (number)
				if (_back.card_id_x >= 0 && _back.card_id_y >= 0)
				{
					command = command + "<cardId>" +
					                    "<x>" + _back.card_id_x.toString() + "</x>" +
					                    "<y>" + _back.card_id_y.toString() + "</y>";
 					if (_cardData.number.toString().length > 0) // otherwise service will use the card id from the card
						command = command + "<value>" + _cardData.number + "</value>";
					command = command + "</cardId>";
				}
				// card id barcode
				if (_back.card_id_barcode_x >= 0 && _back.card_id_barcode_y >= 0)
				{
					command = command + "<cardIdBarcode>" +
					                    "<x>" + _back.card_id_barcode_x.toString() + "</x>" +
					                    "<y>" + _back.card_id_barcode_y.toString() + "</y>";
 					if (_cardData.number.toString().length > 0) // otherwise service will use the card id from the card
						command = command + "<value>" + _cardData.number + "</value>";
					command = command + "</cardIdBarcode>";
				}
				// card number (PAN)
				if (_back.card_number_x >= 0 && _back.card_number_y >= 0)
				{
					command = command + "<cardNumber>" +
					                    "<x>" + _back.card_number_x.toString() + "</x>" +
					                    "<y>" + _back.card_number_y.toString() + "</y>";
					if (_cardData.track2.toString().length > 0) // otherwise service will use the pan from the card
						command = command + "<value>" + _cardData.track2.split('=',1)[0] + "</value>";
					command = command + "</cardNumber>";
				}
				// card number barcode
				if (_back.card_number_barcode_x >= 0 && _back.card_number_barcode_y >= 0)
				{
					command = command + "<cardNumberBarcode>" +
					                    "<x>" + _back.card_number_barcode_x.toString() + "</x>" +
					                    "<y>" + _back.card_number_barcode_y.toString() + "</y>";
					if (_cardData.track2.toString().length > 0) // otherwise service will use the pan from the card
						command = command + "<value>" + _cardData.track2.split('=',1)[0] + "</value>";
					command = command + "</cardNumberBarcode>";
				}
				// serial number
				if (_back.serial_x >= 0 && _back.serial_y >= 0 && _cardData.serial.toString().length > 0)
					command = command + "<serial>" +
					                    "<x>" + _back.serial_x.toString() + "</x>" +
					                    "<y>" + _back.serial_y.toString() + "</y>" +
					                    "<value>" + _cardData.serial + "</value>" +
					                    "</serial>";
				// PIN
				if (_back.pin_x >= 0 && _back.pin_y >= 0 && _cardData.pin.toString().length > 0)
					command = command + "<pin>" +
					                    "<x>" + _back.pin_x.toString() + "</x>" +
					                    "<y>" + _back.pin_y.toString() + "</y>" +
					                    "<value>" + _cardData.pin + "</value>" +
					                    "</pin>";
			}
			// Issue Date
			if (_cardStock == HostModel.CARD_STOCK_PREPRINTED_BACK ||
				  (_back.issue_date_x >= 0 && _back.issue_date_y >= 0 && _issueDate.toString().length > 0))
				command = command + "<issueDate>" +
				                    "<x>" + _back.issue_date_x.toString() + "</x>" +
				                    "<y>" + _back.issue_date_y.toString() + "</y>" +
				                    "<value>" + _issueDate + "</value>" +
				                    "</issueDate>";
			// Value
			if (_cardStock == HostModel.CARD_STOCK_PREPRINTED_BACK ||
				  (_back.value_x >= 0 && _back.value_y >= 0 && _value.toString().length > 0))
				command = command + "<amount>" +
				                    "<x>" + _back.value_x.toString() + "</x>" +
				                    "<y>" + _back.value_y.toString() + "</y>" +
				                    "<value>" + _value + "</value>" +
				                    "</amount>";
			command = command + "</back>";
			if (_cardData != null)
			{
				// Track 1
				if (_cardData.track1.toString().length > 0)
					command = command + "<track1>" + _cardData.track1 + "</track1>";
				// Track 2
				if (_cardData.track2.toString().length > 0)
					command = command + "<track2>" + _cardData.track2 + "</track2>";
				// Track 3
				if (_cardData.track3.toString().length > 0)
					command = command + "<track3>" + _cardData.track3 + "</track3>";
			}
			command = command + "</command>";
			trace("DataCardService::retry() - Sending " + command);
			sendCommand ( command );
		}

		protected function sendCommand ( command : String ) : void
		{
			if ( socket && socket.connected )
			{
				socket.writeUTFBytes ( command );
				socket.flush();
			}
		}

		public function get state ( ) : int
		{
			return _state;
		}

		public function get isPrinting ( ) : Boolean
		{
			return _isPrinting;
		}

		public function get lastError ( ) : Object
		{
			return _lastError;
		}

		public function connect ( ) : void
		{
			trace ( "connecting dc service");
			socket = new Socket();
			socket.addEventListener ( Event.CONNECT, handleConnect, false, 0, true );
			socket.addEventListener ( IOErrorEvent.IO_ERROR, handleError, false, 0, true );
			socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, handleSecurityError, false, 0, true );
			socket.addEventListener ( ProgressEvent.SOCKET_DATA, readSocketData, false, 0, true );
			socket.connect ( HOST, PORT );
		}

		protected function handleConnect ( evt : Event ) : void
		{
			trace ( "DataCardService::connect()");
			ready = true;

			dispatchEvent ( new Event ( Event.CONNECT ) );
		}

		protected function handleError ( evt : ErrorEvent ) : void
		{
			trace ( "DataCardService::error -> " + evt.toString());
			dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.ERROR, evt) );
		}

		protected function handleSecurityError ( evt : ErrorEvent ) : void
		{
			trace ( "DataCardService::Security error -> " + evt.toString());
		}

		protected function readSocketData ( evt : ProgressEvent ) : void
		{
			var buffer : String = socket.readUTFBytes ( socket.bytesAvailable );
			trace ( "DataCardService::recv(" + buffer + ")");

			var buffers : Array = buffer.split ( "\n" );

			for ( var i : int = 0; i < buffers.length; i++ )
			{
				var bufferPart : String = buffers[i];
				try
				{
					var command : Object = JSON.parse ( bufferPart );
					processCommand ( command );
				}catch ( e : Error )
				{
					// Most likely an incomplete packet;
				}
			}
		}

		protected function handleServiceError ( command : Object ) : void
		{
			_lastError = command;
			dispatchEvent ( new DataCardServiceEvent ( DataCardServiceEvent.ERROR_RECEIVED, command ) );

			_isPrinting = false;
		}

		public function dispose ( ) : void
		{
			if ( socket && socket.connected )
			{

				socket.removeEventListener ( Event.CONNECT, handleConnect );
				socket.removeEventListener ( IOErrorEvent.IO_ERROR, handleError );
				socket.removeEventListener ( SecurityErrorEvent.SECURITY_ERROR, handleError );
				socket.removeEventListener ( ProgressEvent.SOCKET_DATA, readSocketData );

				socket.close();
				socket = null;
			}

			_isPrinting = false;
		}

		protected function processCommand ( command : Object ) : void
		{
			var oldState : int = state;

			if ( command.errorState != DataCardError.NO_ERROR )
			{
				handleServiceError ( command );
				_state = command.state;
			}

			_lastData = command;

			if ( oldState != command.state )
			{
				dispatchEvent ( new DataCardServiceEvent ( DataCardServiceEvent.STATE_CHANGE, command ) );
			}

			_state = command.state;

			if ( command.state == DataCardState.FINISHED ) reset();
		}
	}

}
