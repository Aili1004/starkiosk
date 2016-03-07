
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

	public class ClearingReceiptPrintingService extends EventDispatcher
	{
		protected var template : String = "";
		protected var printerTemplateToSend : String = "";

    public function ClearingReceiptPrintingService()
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
			Logger.log ( "Clearing Receipt Template Loaded..." );
			this.template = evt.target.data;

			Controller.getInstance().report ( 0, "Clearing Receipt Template loaded" );
		}

		protected function onTemplateError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error loading clearing receipt template", Logger.ERROR );
			Controller.getInstance().report ( 10, "Error loading clearing receipt template" );
		}

		public function print ( propertyMap : Object ) : void
		{
			var template : String = this.template + "";

			propertyMap.date_time = StringUtil.getDateTime();
			propertyMap.kiosk_id = Environment.KIOSK_UNIQUE_ID;

			template = StringUtil.replaceKeys ( template, propertyMap );

			if ( propertyMap.barcode )
			{
				template = template.replace ( "${barcode=n}", "{barcode=" + propertyMap.barcode + "}");
			}

			this.printerTemplateToSend = template;
			trace ( "Clearing Receipt:\n" + this.printerTemplateToSend );

			var socket : Socket = new Socket();
			socket.addEventListener ( Event.CONNECT, writeTemplate, false, 0, true );
			socket.addEventListener ( IOErrorEvent.IO_ERROR, onReceiptError, false, 0, true );
			socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onReceiptSecurityError, false, 0, true );
			socket.connect ( Environment.SERVICE, 1999 );
		}

		protected function onReceiptError ( evt : ErrorEvent ) : void
		{
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