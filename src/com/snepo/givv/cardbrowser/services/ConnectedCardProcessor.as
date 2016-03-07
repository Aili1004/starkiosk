package com.snepo.givv.cardbrowser.services
{

	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.*;

	import com.adobe.serialization.json.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class ConnectedCardProcessor extends EventDispatcher
	{
		public static const ACTIVATING				: String = "CardProcessor.ACTIVATING";
		public static const PRINTER_FEED_PENDING  	: String = "CardProcessor.PRINTER_FEED_PENDING";
		public static const PRINTER_READ_PENDING  	: String = "CardProcessor.PRINTER_READ_PENDING";
		public static const CARD_TRANSFER_PENDING  	: String = "CardProcessor.CARD_TRANSFER_PENDING";
		public static const PRINTER_PRINT_PENDING 	: String = "CardProcessor.PRINTER_PRINT_PENDING";
		public static const GATEWAY_CONFIRM_PENDING	: String = "CardProcessor.GATEWAY_CONFIRM_PENDING";

		protected var service : DataCardService;
		protected var _state : String = "idle";
		protected var printAttempts : Number = 0;
		public var data : XML;
		protected var simulate : Boolean = false;

		public function ConnectedCardProcessor( service : DataCardService )
		{
			super(this);

			this.service = service;
		}

		public function set state ( s : String ) : void
		{
			_state = s;

			dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.STATE_CHANGE, s ) );
		}

		public function get state ( ) : String
		{
			return _state;
		}

		public function start ( data : XML = null ) : void
		{
			trace('ConnectCardProcessor::start() - data = ' + data)
			printAttempts = 0;

			if ( data != null ) this.data = data;

			if ( data.@processas == CardModel.SCANNABLE || data.@processas == CardModel.VIRTUAL || Number (data.cost.text()) == 0 )
			{
				// Animate screeen for Virtual and Scannable products
				simulate = true;
				state = ACTIVATING;

				if ( data.@processas == CardModel.SCANNABLE )
				{
					TweenMax.delayedCall ( 1, transferCard, [data.number] );
				}
				else
					TweenMax.delayedCall ( 2, notifyComplete );
			}else
			{
				//this.readJob();
				simulate = false;
				var url : String = Model.getInstance().cards.getPrintURL ( this.data.productid.text() + "" );
				var value : String = StringUtil.currencyLabelFunction ( this.data.cost.text() ) + "";
				if ( Number ( this.data.cost.text() ) < 1 )
					value = Number ( this.data.cost.text() ).toFixed ( 2 ).replace ( ".00", "" ) + "c";
				var product : Object = Model.getInstance().cards.getCardByID( this.data.productid.text() + "" );
				var issueDate : String = StringUtil.getDate ( new Date(), (product.api == CardModel.BLACKHAWK ? false : true ));

				service.printCard ( url, issueDate, value, product.backID, data.cardData[0] );
			}
		}

		protected function notifyComplete()
		{
			dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.COMPLETE ) );
		}

		protected function notifyError ( reason : String = "Unknown") : void
		{
			dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.ERROR, reason ) );
		}

		public function connect()
		{
			service.addEventListener ( DataCardServiceEvent.STATE_CHANGE, handleStateChange, false, 0, true );
			service.addEventListener ( DataCardServiceEvent.ERROR_RECEIVED, handleServiceError, false, 0, true );
		}

		public function release ( ) : void
		{
			service.removeEventListener ( DataCardServiceEvent.STATE_CHANGE, handleStateChange );
			service.removeEventListener ( DataCardServiceEvent.ERROR_RECEIVED, handleServiceError );
		}

		protected function handleStateChange ( evt : DataCardServiceEvent ) : void
		{
			switch ( evt.command.state )
			{
				case DataCardState.PREPARING :
				{
					break;
				}

				case DataCardState.FEEDING :
				{
					state = PRINTER_FEED_PENDING;
					break;
				}

				case DataCardState.READING :
				{
					state = PRINTER_READ_PENDING;
					break;
				}

				case DataCardState.READ_SUCCESS :
				{
					trace ( "********* TRACK DATA = " + evt.command.message );
					state = CARD_TRANSFER_PENDING;
					transferCard ( evt.command.message );
					break;
				}

				case DataCardState.PRINTING :
				{
					state = PRINTER_PRINT_PENDING;
					break;
				}

				case DataCardState.TIDYING :
				{
					break;
				}

				case DataCardState.FINISHED :
				{
				  trace ( "********* RIBBON REMAINING = " + evt.command.message );
					state = GATEWAY_CONFIRM_PENDING;
					confirmCard ( evt.command.message );
					break;
				}
			}
		}

		protected function transferCard ( cardID : String ) : void
		{
			trace ('ConnectedCardPrinter::transferCard() - CardID = ' + cardID)
			Model.getInstance().cards.cardIDMap [ data.@id + "" ] = cardID;

			var cardTransferToken : CardTransferToken = new CardTransferToken();
				cardTransferToken.addEventListener ( TokenEvent.COMPLETE, onCardTransferSuccess );
				cardTransferToken.addEventListener ( TokenEvent.ERROR, onCardTransferError );
				cardTransferToken.start ( {cardID : data.@id, printerCardID : cardID} );
		}

		protected function onCardTransferSuccess ( evt : TokenEvent ) : void
		{
			trace ( "ConnectedCardProcessor::onCardTransferSuccess() - response: " + evt.data.toString());
			if ( simulate && data.@processas == CardModel.SCANNABLE )
				notifyComplete();
			else if (Model.getInstance().host.cardStock == HostModel.CARD_STOCK_BLANK && data.@processas == CardModel.PRINTABLE)
				service.printCardFinalisation ( evt.data.cardData[0] );
		}

		protected function onCardTransferError ( evt : TokenEvent ) : void
		{
			trace ( "Card Transfer error - > " + evt.data );
			if ( (Model.getInstance().host.cardStock == HostModel.CARD_STOCK_BLANK) )
				notifyError( evt.data + "" ); // stop if unable to retreive card data
		}

		protected function confirmCard ( ribbonLevel : String ) : void
		{
			var confirmToken : GatewayConfirmToken = new GatewayConfirmToken();
				confirmToken.addEventListener ( TokenEvent.COMPLETE, onGatewayConfirmSuccess );
				confirmToken.addEventListener ( TokenEvent.ERROR, onGatewayConfirmError );
				confirmToken.start ( {cardID : data.@id, ribbonLevel : ribbonLevel, printerCardID : Model.getInstance().cards.cardIDMap[data.@id + ""]} );
		}

		protected function onGatewayConfirmSuccess ( evt : TokenEvent ) : void
		{
			// DONE
			notifyComplete();
		}

		protected function onGatewayConfirmError ( evt : TokenEvent ) : void
		{
			//notifyComplete();
			notifyError( evt.data + "" );
		}

		protected function handleServiceError ( evt : DataCardServiceEvent ) : void
		{
			// TODO: get error string
			printAttempts++;

			switch ( service.lastError.errorState )
			{
				// Fatal errors
				case DataCardError.NO_PRINTER:
				case DataCardError.INVALID_PRINTER:
				case DataCardError.PRINT_FAILED: // don't retry for hard error
				{
					notifyError ( DataCardError.toString(service.lastError.errorState) );
					break;
				}

				default:
				{
					trace ( "Retrying in 2 seconds...");
					if (printAttempts > 5)
						notifyError("Failed to print card");
					else
					{
						Logger.log("Failed to print. Retrying (" + printAttempts.toString() + ")");
						TweenMax.delayedCall ( 2, service.retry );
					}
					break;
				}
			}
		}
	}

}