package com.snepo.givv.cardbrowser.services
{

	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.view.controls.*;

	import flash.events.*;
	import flash.net.*;

	public class CoinReceiptPrintingService extends EventDispatcher
	{
		protected var template : String = "";
		protected var printerTemplateToSend : String = "";

		public var mode : String = "Coin";

    	public function CoinReceiptPrintingService()
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
			Logger.log ( mode + " Receipt Template Loaded..." );
			this.template = evt.target.data;

			Controller.getInstance().report ( 0, mode + " Receipt Template loaded" );
		}

		protected function onTemplateError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error loading " + mode + " receipt template", Logger.ERROR );
			Controller.getInstance().report ( 10, "Error loading " + mode + " receipt template" );
		}

		public function print ( propertyMap : Object ) : void
		{
			var isError : Boolean = propertyMap.hasError == true;

			var template : String = this.template + "";

			if ( isError )
			{
				propertyMap.errors = "{cr}\n{emph_on}{bold_on}{center}YOUR TRANSACTION FAILED.{cr}\nPLEASE CONTACT GIVV TO RECTIFY{bold_off}{emph_off}{left}\n{cr}\n{cr}";
			}else
			{
				propertyMap.errors = "";
			}

			var dateTime : String = StringUtil.getDateTime();
			var kioskID : String = Environment.KIOSK_UNIQUE_ID;

			propertyMap.date_time = dateTime;
			propertyMap.kiosk_id = kioskID;

			template = StringUtil.replaceKeys ( template, propertyMap );

			if ( propertyMap.barcode )
			{
				template = template.replace ( "${barcode=n}", "{barcode=" + propertyMap.barcode + "}");
			}

			this.printerTemplateToSend = template;
			trace ( "Coin Receipt:\n" + this.printerTemplateToSend );

			var socket : Socket = new Socket();
				socket.addEventListener ( Event.CONNECT, writeTemplate, false, 0, true );
				socket.addEventListener ( IOErrorEvent.IO_ERROR, onReceiptError, false, 0, true );
				socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onReceiptSecurityError, false, 0, true );
				socket.connect ( Environment.SERVICE, 1999 );

			//trace ( queue.toXMLString() );
		}

		protected function onReceiptError ( evt : ErrorEvent ) : void
		{
//			Controller.getInstance().report ( 10, "Error printing receipt" );
			trace("Printer Error = " + evt.text);
			View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( '153' ) ) );
		}

		protected function onReceiptSecurityError ( evt : ErrorEvent ) : void
		{
			Controller.getInstance().report ( 10, "Error printing receipt - " + evt.text );
		}

		protected function writeTemplate ( evt : Event ) : void
		{
			var socket : Socket = evt.target as Socket;
			var message : String = this.printerTemplateToSend.split("\n").join("^");

			socket.writeUTFBytes ( message );
			socket.flush();
		}
	}

}