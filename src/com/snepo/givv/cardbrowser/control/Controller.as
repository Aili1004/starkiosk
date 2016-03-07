package com.snepo.givv.cardbrowser.control
{
	import com.snepo.givv.cardbrowser.services.pinpad.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class Controller extends EventDispatcher
	{
		protected static var instance : Controller;

		public static function getInstance ( ) : Controller
		{
			instance ||= new Controller ( new Private() );
			return instance;
		}

		public var receiptPrinter : ReceiptPrintingService;
		public var messagePrinter : MessagePrintingService;
		public var coinReceiptPrinter : CoinReceiptPrintingService;
		public var clearingReceiptPrinter : ClearingReceiptPrintingService;
		protected var _currentPrinterService : CardPrintingService;
		protected var health : HealthManager;

		protected var pinPadService : PinPadService;

   	public function Controller ( p : Private )
		{
			super ( this );
			if ( p == null ) throw new SingletonError ( "Controller" );

			receiptPrinter = new ReceiptPrintingService();
			receiptPrinter.loadTemplate ( "data/" );

			messagePrinter = new MessagePrintingService();
			messagePrinter.loadTemplate ( "data/message.txt" );

			coinReceiptPrinter = new CoinReceiptPrintingService();
			coinReceiptPrinter.mode = "Coin";
			coinReceiptPrinter.loadTemplate ( "data/coinreceipt.txt");

			clearingReceiptPrinter = new ClearingReceiptPrintingService();
			clearingReceiptPrinter.loadTemplate ( "data/clearingreceipt.txt");

			health = HealthManager.getInstance();
		}

		public function testServices( ) : void
		{
			receiptPrinter.testConnection();
		}

		public function report ( score : int, status : String ) : void
		{
			health.report ( score, status );
		}

		public function reset ( ) : void
		{
			Logger.log("Controller Reset");
			var model : Model = Model.getInstance();
			model.cart.drain();
			model.cards.currentScanData = null;
			model.user.clearUser();
			if (model.host.paymentOption != HostModel.PAYMENT_OPTION_DISABLE_CARDS)
				model.cart.paymentMethod = CartModel.CARDS;
			else if (model.host.paymentOption != HostModel.PAYMENT_OPTION_DISABLE_NOTES)
				model.cart.paymentMethod = CartModel.NOTES;
			else
				model.cart.paymentMethod = CartModel.COINS;

			View.getInstance().reset();
		}

		protected function onResetSuccess ( evt : TokenEvent ) : void
		{
			report ( 0, "Reset Printer" );
		}

		public function completeTransaction():void
		{
			printReceipt ( { receipt_id : currentPrinterService.refID, credit_card_number : currentPrinterService.finalDigits, merchant_transaction_id : currentPrinterService.currentTransactionID } );

			var overlay : GenericMessageOverlay = new GenericMessageOverlay();
				overlay.data = { title : "Thank you for\nusing " + Environment.companyName, message : "Please collect your receipt" };
				overlay.addEventListener ( Event.CLOSE, handleCompleteOverlayClose, false, 0, true );

			var image : MovieClip = new ReceiptImage();
				image.y = overlay.height - image.height;
				image.x = 0;

			overlay.addChild ( image );

			View.getInstance().modalOverlay.currentContent = overlay;
			destroyPrintService();
		}

		public function checkCardBalance ( number : String ) : CheckBalanceToken
		{
			var token : CheckBalanceToken = new CheckBalanceToken();
				token.start ( number );

			return token;
		}

		public function startCoinPayment ( ) : CardPrintingService
		{
			var model : Model = Model.getInstance();
			var cart : XML = model.cart.getPrinterQueue();

			var service : CardPrintingService = checkout ( cart );
				service.addEventListener ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL, showPrintingScreen, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.PAYMENT_ERROR, showPaymentError, false, 0, true );

			return service;
		}

		public function getHostGroupInfo ( ) : HostGroupToken
		{
			var token : HostGroupToken = new HostGroupToken();
				token.addEventListener ( TokenEvent.COMPLETE, onGetHostGroupInfoSuccess, false, 0, true );
				token.addEventListener ( TokenEvent.ERROR, onGetHostGroupInfoError, false, 0, true );
				token.start ( { kioskID : Environment.KIOSK_UNIQUE_ID } );

			return token;
		}

		public function startNotePayment ( ) : CardPrintingService
		{
			var model : Model = Model.getInstance();
			var cart : XML = model.cart.getPrinterQueue();

			var service : CardPrintingService = checkout ( cart );
				service.addEventListener ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL, showPrintingScreen, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.PAYMENT_ERROR, showPaymentError, false, 0, true );

			return service;
		}

		protected function showPrintingScreen ( evt : CardPrinterServiceEvent ) : void
		{
			trace("Controller.showPrintingScreen")
			Model.getInstance().user.applyBalances ( ( evt.target as CardPrintingService ).customerBalance );

			View.getInstance().currentScreenKey = View.PRINTING_SCREEN;
			TweenMax.delayedCall ( 1.5, currentPrinterService.processNextCard );
		}

		protected function showPaymentError ( evt : CardPrinterServiceEvent ) : void
		{
			trace("Controller.showPaymentError() -> " + evt.toString());
//			if ( !isNaN ( Number ( evt.data ) ) )
//			{
			if ( evt.data.hasOwnProperty('text'))
 				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data.text ) ) )
			else
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data ) ) )
//			}else
//			{
//			  	View.getInstance().addChild ( Alert.show ( { title : "Error processing payment", message : evt.data, buttons : [ "OK" ] } ) )	
//			}

			var confirm : ConfirmScreen = View.getInstance().getScreen ( View.CONFIRM_SCREEN ) as ConfirmScreen;
				confirm.checkoutBtn.enabled = true;
				confirm.state = ConfirmScreen.CONFIRM;
		}

		protected function onGetHostGroupInfoError ( evt : TokenEvent ) : void
		{
			var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( evt.data ) );
			var view : View = View.getInstance();
				view.addChild ( alert );
		}

		protected function onGetHostGroupInfoSuccess ( evt : TokenEvent ) : void
		{
			var model : Model = Model.getInstance();
			model.host.populate ( evt.data );
			if (model.host.receiptText.length > 0) receiptPrinter.template = model.host.receiptText;
			if (model.host.receiptErrorText.length > 0) receiptPrinter.errorTemplate = model.host.receiptErrorText;
		}

		protected function handleCompleteOverlayClose ( evt : Event ) : void
		{
			reset();
		}

		public function startPinPadTransaction ( ) : void
		{

			pinPadService = new PinPadService();
			pinPadService.amount = Model.getInstance().cart.commissionedTotal;
			pinPadService.txnID = "Givv_txn_" + Math.round ( Math.random() * 9999999999 );
			pinPadService.connect();

			var view : View = View.getInstance();
				view.startPinPadTransaction ( pinPadService );

		}

		public function review ( cart : XML, subtractFees : Boolean = false ) : ReviewCartToken
		{
			var reviewCartToken : ReviewCartToken = new ReviewCartToken();
				reviewCartToken.startEx ( cart, subtractFees );

			return reviewCartToken;

		}

		public function checkout ( cart : XML ) : CardPrintingService
		{
			Logger.log( "Processing Checkout...");
			_currentPrinterService = new CardPrintingService();
			_currentPrinterService.process ( cart );

			return _currentPrinterService;
		}

		public function get currentPrinterService ( ) : CardPrintingService
		{
			return _currentPrinterService;
		}

		public function destroyPrintService ( ) : void
		{
			_currentPrinterService.dispose();
			_currentPrinterService = null;
		}

		public function printReceipt ( propertyMap : Object ) : void
		{
			receiptPrinter.print ( propertyMap );
		}

		public function printMessage ( message : String ) : void
		{
			messagePrinter.print ( message );
		}

		public function printCoinReceipt ( propertyMap : Object ) : void
		{
			trace ( "printing coin receipt");
			coinReceiptPrinter.print ( propertyMap );
		}

		public function printClearingReceipt ( propertyMap : Object ) : void
		{
			trace ( "printing clearing receipt");
			clearingReceiptPrinter.print ( propertyMap );
		}

	}
}

class Private{};
