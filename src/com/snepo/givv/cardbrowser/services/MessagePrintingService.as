package com.snepo.givv.cardbrowser.services
{
	
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;
		
	import flash.events.*;
	import flash.net.*;

	public class MessagePrintingService extends EventDispatcher
	{
		protected var template : String = "";
		protected var printerTemplateToSend : String = "";

    	public function MessagePrintingService()
		{
			super ( this );  
		}

		public function loadTemplate ( path : String ) : void
		{
			var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, onTemplateLoaded );
				loader.addEventListener ( IOErrorEvent.IO_ERROR, onTemplateError );
				loader.load ( new URLRequest ( path ) );
		}

		protected function onTemplateLoaded ( evt : Event ) : void
		{
			this.template = evt.target.data;

			Controller.getInstance().report ( 0, "Message Template loaded" );

		}

		protected function onTemplateError ( evt : ErrorEvent ) : void
		{
			Controller.getInstance().report ( 10, "Error loading message template" );

		}

		public function print ( message : String ) : void
		{
			var template : String = this.template + "";
			var dateTime : String = StringUtil.getDateTime();
			var kioskID : String = Environment.KIOSK_UNIQUE_ID;
			
			template = template.replace ( "${date_time}", dateTime );
			template = template.replace ( "${kiosk_id}", kioskID );
			template = template.replace ( "${message}", message );

			this.printerTemplateToSend = template
			trace ( "Printing Message:\n" + this.printerTemplateToSend );	

			var socket : Socket = new Socket();
				socket.addEventListener ( Event.CONNECT, writeTemplate );
				socket.addEventListener ( IOErrorEvent.IO_ERROR, onReceiptError );
				socket.connect ( Environment.SERVICE, 1999 );
		}

		protected function writeTemplate ( evt : Event ) : void
		{
			var socket : Socket = evt.target as Socket;
			var message : String = this.printerTemplateToSend.split("\n").join("^");

			socket.writeUTFBytes ( message );
			socket.flush();
		}

		protected function onReceiptError ( evt : ErrorEvent ) : void
		{
			Controller.getInstance().report ( 10, "Error printing error message" );
		}
	}

}