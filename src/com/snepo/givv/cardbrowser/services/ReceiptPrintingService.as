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

	public class ReceiptPrintingService extends EventDispatcher
	{
		protected var _template : String = "";
		protected var _errorTemplate : String = "";
		protected var printerTemplateToSend : String = "";

    public function ReceiptPrintingService()
		{
			super ( this );
		}

		public function loadTemplate ( path : String ) : void
		{
			var loader : URLLoader = new URLLoader();
			loader.addEventListener ( Event.COMPLETE, onTemplateLoaded );
			loader.addEventListener ( IOErrorEvent.IO_ERROR, onTemplateError );
			loader.load ( new URLRequest ( path + "receipt.txt" ) );
			var errorLoader : URLLoader = new URLLoader();
			errorLoader.addEventListener ( Event.COMPLETE, onErrorTemplateLoaded );
			errorLoader.addEventListener ( IOErrorEvent.IO_ERROR, onErrorTemplateError );
			errorLoader.load ( new URLRequest ( path + "receipt_error.txt" ) );
		}

		public function set template ( t : String )
		{
			_template = t;
		}

		public function set errorTemplate ( t : String )
		{
			_errorTemplate = t;
		}

		public function testConnection ( ) : void
		{
			var socket : Socket = new Socket();
				socket.addEventListener ( Event.CONNECT, onConnectionTestSuccess, false, 0, true );
				socket.addEventListener ( IOErrorEvent.IO_ERROR, onConnectionTestError, false, 0, true );
				socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onConnectionTestError, false, 0, true );
				socket.connect ( Environment.SERVICE, 1999 );
		}

		protected function onTemplateLoaded ( evt : Event ) : void
		{
			_template = evt.target.data;

			Logger.log ( "Receipt Template Loaded..." );
			Controller.getInstance().report ( 0, "Receipt Template loaded" );
		}

		protected function onTemplateError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error loading receipt template", Logger.ERROR );
			Controller.getInstance().report ( 10, "Error loading receipt template" );
		}

		protected function onErrorTemplateLoaded ( evt : Event ) : void
		{
			_errorTemplate = evt.target.data;

			Logger.log ( "Receipt Error Template Loaded..." );
			Controller.getInstance().report ( 0, "Receipt Error Template loaded" );
		}

		protected function onErrorTemplateError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error loading receipt error template", Logger.ERROR );
			Controller.getInstance().report ( 10, "Error loading receipt error template" );
		}

		public function print ( propertyMap : Object ) : void
		{
			var items : XMLList = Controller.getInstance().currentPrinterService.cardsToProcess;

			var totalItems : Number = 0;
			var totalCost : Number = 0;

			var cardEntries : String = "";
			var fees : Number = 0;
			var totalFees : Number = 0;

			var messageEntries : String = "";
			var partnerIDs : Array = [];

			var i : int;
			var failureReceipt : Boolean = (propertyMap.hasOwnProperty("cardsProcessed") ? true : false);

			var model : Model = Model.getInstance();
			/*

			Payment Receipt ID
			Merchant Transaction ID
			* remove credit card number

			for each card

				card type : PGA
				card value : value of card, not cost
				  processing fees : $20;

			end

			Total Cost: including fees
			*/

			for ( i = 0; i < items.length(); i++ )
			{
				var item : XML = items[i];
				totalItems ++;
				totalCost += ( Number ( item.totalcost.text() ) );

				var card : Object = model.cards.getCardByID ( item.productid.text() + "" );
				var name : String = card.name;
				var cardID : String = model.cards.cardIDMap [ item.@id + "" ];

				// Crack BHN PAN
				if (cardID != null)
				{
					var pattern : RegExp = /B\d{16,19}/;
					var pan = cardID.match(pattern)
					if (pan != null) cardID = pan[0].replace("B","");
				}
				var delta : Number = 0;
				var cardValue : Number;
				var len : int;

				if (failureReceipt)
				{
					if (i == 0 && i != propertyMap.cardsProcessed)
						cardEntries += "{bold_on}" +
													 "=============================================={cr}" +
													 "            SUCCESSFULLY PROCESSED            {bold_off}{cr}\n{cr}\n";
					else
					if (i == propertyMap.cardsProcessed)
						cardEntries += "{bold_on}" +
													 "=============================================={cr}" +
													 "           UNSUCCESSFULLY PROCESSED           {bold_off}{cr}\n{cr}\n";

				}

				if ( card.processas != CardModel.VIRTUAL )
				{

					cardValue = Number ( item.cost.text() );
					cardEntries += "{bold_on}Card Type :{bold_off} " + name + "{cr}\n";

					if (cardValue > 0 && cardID)
					{
						len = cardID.length

						if (len > 9) // Not eMerchants card id so must be masked
						{
							cardID = cardID.substring ( len-4, len );
							cardID = new Array ( len-3 ).join("*") + cardID;
							if ( cardID ) cardEntries += "{bold_on}Card Number{bold_off} : " + cardID + "{cr}\n";
						}
						else
						if ( cardID ) cardEntries += "{bold_on}Card ID{bold_off} : " + cardID + "{cr}\n";
					}

					if ( cardValue == 0 )
					{
						cardEntries += "{bold_on}Card Value : $0. (Card has not been printed){bold_off}{cr}\n";
					}else
					if ( cardValue < 1 )
					{
						cardEntries += "{bold_on}Card Value :{bold_off} " + cardValue.toFixed ( 2 ).replace ( ".00", "" ) + "c" + "{cr}\n";
					}else
					{
						cardEntries += "{bold_on}Card Value :{bold_off} " + StringUtil.currencyLabelFunction ( item.cost.text() ) + "{cr}\n";
					}


					delta = ( Number ( item.totalcost.text() ) - Number ( item.cost.text() ) );
					totalFees += delta;

					if ( delta != 0 )
					{
						if ( delta < 1 )
						{
							cardEntries += "{bold_on}  Processing Fees* :{bold_off} " + delta.toFixed(2).replace(".00", "") + "c{cr}\n";
						}else
						{
							cardEntries += "{bold_on}  Processing Fees* :{bold_off} " + StringUtil.currencyLabelFunction ( delta ) + "{cr}\n";
						}
					}

					cardEntries += "{cr}\n{cr}\n";
				}else
				{

					cardEntries += "{bold_on}Card Type :{bold_off} " + name + "{cr}";
					cardValue = Number ( item.cost.text() );
					if ( cardValue < 1 )
					{
						cardEntries += "{bold_on}Card Value :{bold_off} " + cardValue.toFixed ( 2 ).replace ( ".00", "" ) + "c" + "{cr}\n";
					}else
					{
						cardEntries += "{bold_on}Card Value :{bold_off} " + StringUtil.currencyLabelFunction ( item.cost.text() ) + "{cr}\n";
					}

					delta = ( Number ( item.totalcost.text() ) - Number ( item.cost.text() ) );

					if ( delta != 0 )
					{
						if ( delta < 1 )
						{
							cardEntries += "{bold_on}  Processing Fees* :{bold_off} " + delta.toFixed(2).replace(".00", "") + "c{cr}\n";
						}else
						{
							cardEntries += "{bold_on}  Processing Fees* :{bold_off} " + StringUtil.currencyLabelFunction ( delta ) + "{cr}\n";
						}
						totalFees += delta;
					}

					if ( cardID )
					{
						cardEntries += "{bold_on}Recharge PIN:{bold_off}"
						cardEntries += cardID + "{cr}\n";
					}
					cardEntries += "See end of receipt for full terms\n";
					cardEntries += "{cr}\n{cr}\n{cr}";
				}
				if (failureReceipt &&
					  (i == propertyMap.cardsToProcess - 1 || i == items.length()-1))
					cardEntries += "{bold_on}" +
												 "=============================================={bold_off}{cr}{cr}";

				if ( partnerIDs.indexOf ( card.partnerID ) < 0 ) partnerIDs.push ( card.partnerID );
			}

			for ( i = 0; i < partnerIDs.length; i++ )
			{
				var receiptMessage : String = model.partners.getReceiptText( partnerIDs[i] );
				if ( receiptMessage.length > 0)
				{
					receiptMessage = receiptMessage.split("\n").join("{cr}\n");
					messageEntries += receiptMessage;
				}
			}

			messageEntries += "\n{cr}\n{cr}\n{cr}";

			var newGST : Number = /*Math.floor*/ ( ( totalFees / 0.11 ) / 100 );
			var template : String = _template + "";
			var dateTime : String = StringUtil.getDateTime();
			var kioskID : String = model.host.displayName;
			var cardTotals : String = "";
			for ( i=0; i < model.cart.transactionFees.length; i++ )
			{
				cardTotals += "{bold_on}" + model.cart.transactionFees[i].description + ":{bold_off} $" + model.cart.transactionFees[i].cost.toFixed(2).replace(".00","") + "\n{cr}";
				totalCost += model.cart.transactionFees[i].cost;
			}
			cardTotals += "{bold_on}Total Amount :{bold_off} $" + (totalCost).toFixed(2).replace(".00", "") + "\n{cr}";
			if (Environment.isGivv && newGST != 0) cardTotals += "{bold_on}*Includes GST of :{bold_off} $" + newGST.toFixed(2).replace(".00", "") + "\n{cr}";

			propertyMap.date_time = dateTime;
			propertyMap.kiosk_id = kioskID;
			propertyMap.card_entries = cardEntries;
			propertyMap.card_totals = cardTotals;
			propertyMap.partner_text = messageEntries;
			propertyMap.card_fees = "Total activation fees : " + StringUtil.currencyLabelFunction ( fees );

			// error header
			if (propertyMap.hasOwnProperty("error_text"))
				propertyMap.header = StringUtil.replaceKeys ( _errorTemplate, propertyMap )
			else
				propertyMap.header = '';

			template = StringUtil.replaceKeys ( template, propertyMap );

			this.printerTemplateToSend = template;
			trace ( "?> " + this.printerTemplateToSend );

			var socket : Socket = new Socket();
				socket.addEventListener ( Event.CONNECT, writeTemplate, false, 0, true );
				socket.addEventListener ( IOErrorEvent.IO_ERROR, onReceiptError, false, 0, true );
				socket.addEventListener ( SecurityErrorEvent.SECURITY_ERROR, onReceiptSecurityError, false, 0, true );
				socket.connect ( Environment.SERVICE, 1999 );

		}

		protected function onConnectionTestSuccess ( evt : Event ) : void
		{
			trace("Receipt Printer Service OK");
			Controller.getInstance().report ( 0, "Receipt printer connection OK." );
		}

		protected function onConnectionTestError ( evt : ErrorEvent ) : void
		{
			trace("Receipt Printer Service CONNECTION ERROR - " + evt.toString());
			Controller.getInstance().report ( 50, "Receipt printer connection error." );
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