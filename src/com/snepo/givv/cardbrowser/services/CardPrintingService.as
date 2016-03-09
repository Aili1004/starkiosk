package com.snepo.givv.cardbrowser.services
{
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class CardPrintingService extends EventDispatcher
	{
		public static var PAYMENT_ENDPOINT : String = Environment.hostAddress;

		public static const LOG : Boolean = false;

		protected var initialCart : XML;
		protected var paymentResponse : XML;
		public var cardsToProcess : XMLList;

		protected var cardsProcessed : int = 0;
		public var totalCards 	 : int = 0;

		protected var currentCardProcessor : ConnectedCardProcessor;
		protected var currentCardData : XML;

		protected var cardIndexMap : Dictionary;
		public var finalDigits : String;
		public var refID : String = "";

		protected var _customerBalance : XML;

		protected var service : DataCardService;

		public function CardPrintingService()
		{
			super ( this );
			cardIndexMap = new Dictionary();
		}

		public function dispose ( ) : void
		{
			service.removeEventListener ( Event.CONNECT, onServiceConnected );
			service.dispose();

			service = null;
		}

		public function process ( cart : XML ) : void
		{
			// Set initial cart
			Model.getInstance().cards.cardIDMap = new Dictionary();
			this.initialCart = cart;

			// Connect to printer service
			service = new DataCardService()
			service.addEventListener ( Event.CONNECT, onServiceConnected, false, 0, true );
			service.addEventListener ( CardProcessorEvent.ERROR, onServiceError, false, 0 ,true );
			service.connect();
		}

		protected function onServiceConnected ( evt : Event ) : void
		{
			trace ( "Service connected!");
			this.handlePayment();
		}

		protected function onServiceError ( evt : CardProcessorEvent ) : void
		{
			trace ("Service connection error");
			if (evt.data.text.substr(7,4) == "2031") // socket error
				evt.data.text = '154';

			dispatchEvent ( new CardPrinterServiceEvent ( CardPrinterServiceEvent.PAYMENT_ERROR, evt.data ) );
		}

		protected function handlePayment ( ) : void
		{

			var view : View = View.getInstance();
			var screen : PrintingScreen = view.getScreen ( View.PRINTING_SCREEN ) as PrintingScreen;
				screen.printHasComplete = false;

			var token : GatewayPostToken = new GatewayPostToken();
				token.addEventListener ( TokenEvent.COMPLETE, onHandlePaymentSuccess );
				token.addEventListener ( TokenEvent.ERROR   , onHandlePaymentError );
				token.start ( this.initialCart );
		}


		protected function onHandlePaymentSuccess ( evt : TokenEvent ) : void
		{

			var token : GatewayPostToken = evt.target as GatewayPostToken;

			paymentResponse = token.response as XML;

			_customerBalance = paymentResponse..customer[0];

			injectProcessAsTypesToResponse ( paymentResponse );
			Model.getInstance().cart.injectResponse ( paymentResponse..card );
			cardsToProcess = paymentResponse..card;
			updateVirtualIDMaps ( paymentResponse..card.(@processas=="virtual") );

			finalDigits = paymentResponse.transaction.finaldigits.text();
			refID = paymentResponse.transaction.externalref.text() || "";
			finalDigits = new Array ( ( 16 - finalDigits.length ) ).join("*") + finalDigits;

			injectIndicesToCards ( )

			cardsProcessed = 0;
			totalCards = cardsToProcess.length();

			dispatchEvent ( new CardPrinterServiceEvent ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL ) );

			if ( totalCards > 0 )
			{
				//View.getInstance().currentScreenKey = View.PRINTING_SCREEN;
				//TweenMax.delayedCall ( 1.5, processNextCard );
			}else
			{
				cardsToProcess = paymentResponse..card;
				Controller.getInstance().completeTransaction();
			}
		}

		protected function updateVirtualIDMaps ( list : XMLList ) : void
		{
			for ( var i : int = 0; i < list.length(); i++ )
			{
				var item : XML = list[i];
				var productID : String = item.productid.text() + "";
				/*
				if ( item.@processas == CardModel.SCANNABLE )
				{
					var cardNumber : String = Model.getInstance().cart.getScanNumberByID ( productID );
					Model.getInstance().cards.cardIDMap [ item.@id + "" ] = cardNumber;
				}else
				{*/
				Model.getInstance().cards.cardIDMap [ item.@id + "" ] = item.rechargepin.text();
			//	}

			}
		}

		protected function injectProcessAsTypesToResponse ( paymentResponse : XML ) : void
		{
			var list : XMLList = paymentResponse..card;
			for ( var i : int = 0; i < list.length(); i++ )
			{
				var card : XML = list[i];
				var productID : String = card.productid.text() + "";
				var cardObject : Object = Model.getInstance().cards.getCardByID ( productID );
				if ( cardObject )
				{
					card.@processas = cardObject.processas;
				}
			}
		}

		protected function injectIndicesToCards ( ) : void
		{
			var i : int;
			var card : XML;
			var id : String;
			var value : String = "0";

			for ( i = 0; i < cardsToProcess.length(); i++ )
			{
				card = cardsToProcess [ i ];
				id = ( card.productid.text() );
				value = Math.round ( Number ( card.cost.text() ) ) + "";

//				if ( card.@processas == CardModel.SCANNABLE ) value = card.@id + "";

				var hash : String = id + "_" + value;

				trace ( "HASH: " + hash );

				if ( cardIndexMap [ hash ] == null )
				{
					cardIndexMap [ hash ] = 0;
				}else
				{
					cardIndexMap [ hash ]++
				}

				cardsToProcess[i].@index = cardIndexMap[ hash ];

			}
		}

		public function processNextCard ( ) : void
		{
			if ( currentCardProcessor ) currentCardProcessor.release();

			currentCardProcessor = new ConnectedCardProcessor(service)//new CardProcessor();
			currentCardProcessor.addEventListener ( CardProcessorEvent.COMPLETE, onCardProcessorSuccess, false, 0, true );
			currentCardProcessor.addEventListener ( CardProcessorEvent.PROGRESS, onCardProcessorProgress, false, 0, true )
			currentCardProcessor.addEventListener ( CardProcessorEvent.ERROR, onCardProcessorError, false, 0, true );
			currentCardProcessor.addEventListener ( CardProcessorEvent.STATE_CHANGE, onCardProcessorStateChange, false, 0, true );
			currentCardProcessor.connect();
			currentCardProcessor.start ( cardsToProcess [ cardsProcessed ] );

			currentCardData = cardsToProcess [ cardsProcessed ];

			var eventData : Object = {};
				eventData.index = int(currentCardData.@index);

//				if ( currentCardData.@processas == CardModel.SCANNABLE )
//				{
//					eventData.hash = currentCardData.productid.text() + "_" + currentCardData.@id;
//				}else
//				{
					eventData.hash = currentCardData.productid.text() + "_" + Math.round ( Number ( currentCardData.cost.text() ) );
//				}

				eventData.cardID = currentCardData.@id;

			var event : CardPrinterServiceEvent = new CardPrinterServiceEvent ( CardPrinterServiceEvent.STARTING_CARD, eventData );

			dispatchEvent ( event );
		}

		protected function onCardProcessorStateChange ( evt : CardProcessorEvent ) : void
		{
			dispatchEvent ( new CardPrinterServiceEvent ( CardPrinterServiceEvent.STATE_CHANGE, evt.data ) );
		}

		protected function onCardProcessorSuccess ( evt : CardProcessorEvent ) : void
		{
			cardsProcessed++;

			var eventData : Object = {};
			var event : CardPrinterServiceEvent;

			if ( cardsProcessed >= totalCards )
			{
				cardsToProcess = paymentResponse..card;
				Logger.log ( "All cards processed...");

				eventData.hash = currentCardData.productid.text() + "_" + Math.round ( Number ( currentCardData.cost.text() ) );
				eventData.index = int(currentCardData.@index);
				eventData.cardID = currentCardData.@id;

				event = new CardPrinterServiceEvent ( CardPrinterServiceEvent.CARD_FINISHED, eventData );
				dispatchEvent ( event );

				dispatchEvent ( new CardPrinterServiceEvent ( CardPrinterServiceEvent.COMPLETE ) );

			}else
			{
				eventData.hash = currentCardData.productid.text() + "_" + Math.round ( Number ( currentCardData.cost.text() ) );
				eventData.index = int(currentCardData.@index);
				eventData.cardID = currentCardData.@id;

				trace ( Dumper.toString ( "::::: " + eventData ) );

				event = new CardPrinterServiceEvent ( CardPrinterServiceEvent.CARD_FINISHED, eventData );
				dispatchEvent ( event );

//				TweenMax.delayedCall ( 2, processNextCard );
				processNextCard();
			}
		}

		protected function onCardProcessorProgress ( evt : CardProcessorEvent ) : void
		{
			//Logger.log ( "Progress: " + evt.data.state + " : " + evt.data.percentDone );
			if ( evt.data.state == ConnectedCardProcessor.PRINTER_PRINT_PENDING )
			{
				var eventData : Object = evt.data;

//					if ( currentCardData.@processas == CardModel.SCANNABLE )
//					{
//						eventData.hash = currentCardData.productid.text() + "_" + currentCardData.@id;
//					}else
//					{
						eventData.hash = currentCardData.productid.text() + "_" + Math.round ( Number ( currentCardData.cost.text() ) );
//					}

					eventData.index = int(currentCardData.@index);
					eventData.cardID = currentCardData.@id;

				var event : CardPrinterServiceEvent = new CardPrinterServiceEvent ( CardPrinterServiceEvent.PROGRESS, eventData );
				dispatchEvent ( event );


			}
		}

		public function onCardProcessorError ( evt : CardProcessorEvent ) : void
		{
			var i : int;
			Logger.log ( "Error processing card : " + currentCardProcessor.data );

			var transactionID : String = paymentResponse.transaction.@id;
			var controller : Controller = Controller.getInstance();
			controller.printReceipt ( { receipt_id : controller.currentPrinterService.refID,
																	credit_card_number : controller.currentPrinterService.finalDigits,
																	merchant_transaction_id : controller.currentPrinterService.currentTransactionID,
																	cardsProcessed : cardsProcessed,
																	error_text : evt.data } );
			var errorData : Object = {};
			if ( !isNaN ( Number ( evt.data ) ) )
				errorData = ErrorManager.getErrorByCode ( evt.data );
			else
				errorData = "Error processing card : " + evt.data;

			var event : CardPrinterServiceEvent = new CardPrinterServiceEvent ( CardPrinterServiceEvent.ERROR, errorData );
			dispatchEvent ( event );
		}

		public function get currentTransactionID ( ) : String
		{
			return paymentResponse.transaction.@id;
		}

		public function get customerBalance ( ) : XML
		{
			return _customerBalance;
		}

		/*public function get currentTotalAmount ( ) : Number
		{
			return paymentResponse.transactionID.
		}*/

		protected function onHandlePaymentError ( evt : TokenEvent ) : void
		{
			Logger.log ( "Handle Payment Error => " + evt.data )

			dispatchEvent ( new CardPrinterServiceEvent ( CardPrinterServiceEvent.PAYMENT_ERROR, evt.data ) ); 
		}
	}

}