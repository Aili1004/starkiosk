package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.services.pinpad.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;

	public class PinPadOverlay extends Component implements IOverlay
	{

		public static const STEP_1 : String = "PinPadOverlay.STEP_1";
		public static const STEP_2 : String = "PinPadOverlay.STEP_2";

		protected var line0 : TitleText;
		protected var line1 : TitleText;

		protected var buttons : Array = [];

		protected var _displayData : XML;
		protected var _service : PinPadService;

		public var transactionID : String;
		public var transactionAmt : Number;

		protected var _currentStep : String = STEP_1;

		protected var titleAnimator : TitleText;
		protected var promptAnimator : TitleText;
		protected var step1Animator : TitleText;

		protected var b0 : Button, b1 : Button, b2 : Button;

		public var isSuperModal : Boolean = true;

		public function PinPadOverlay()
		{
			super();

			show();
		}

		public function set currentStep ( s : String ) : void
		{
			_currentStep = s;
			applyStep();
		}

		public function get currentStep ( ) : String
		{
			return _currentStep;
		}

		protected function applyStep ( ) : void
		{
			switch ( currentStep )
			{
				case STEP_1 :
				{
					//cards.y = -90 - 50;
					//cards.alpha = 0;
					//TweenMax.to ( cards, 0.5, { y : -90, alpha : 1, ease : Back.easeOut } );
					promptAnimator.title = "Activating pin pad...\nPlease follow the instructions\non the pin pad to the right";
					break;
				}

				case STEP_2 :
				{

					TweenMax.to ( cancelBtn , 0.5, { autoAlpha : 0 } );
//					TweenMax.to ( step1Animator , 0.5, { autoAlpha : 0 } );
//					TweenMax.to ( cards, 0.5, { y : -90+50, alpha : 0, ease : Quint.easeOut } );
					promptAnimator.title = "Please follow the instructions\non the pin pad to the right";
					break;
				}
			}
		}

		public function onRequestClose ( ) : void
		{
			if ( service )
			{
				service.close();
				service = null;
			}
		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		public function set service ( s : PinPadService ) : void
		{
			_service = s;
			initListeners();
		}

		public function get service ( ) : PinPadService
		{
			return _service;
		}

		protected function initListeners ( ) : void
		{
			service.addEventListener ( PinPadEvent.LOGON, onLoggedOn, false, 0, true );
			service.addEventListener ( PinPadEvent.DISPLAY, updateDisplay, false, 0, true );
			service.addEventListener ( PinPadEvent.CLEAR, clearDisplay, false, 0, true );
			service.addEventListener ( PinPadEvent.TRANSACTION, updateTransactionStatus, false, 0, true );
			service.addEventListener ( PinPadEvent.FAIL, handlePinPadError, false, 0, true );

			for ( var i : int = 0; i < buttons.length; i++ )
			{
				buttons[i].addEventListener ( MouseEvent.CLICK, sendButtonCommand, false, 0, true );
			}
		}

		protected function sendButtonCommand ( evt : MouseEvent ) : void
		{
			var clicked : Button = evt.currentTarget as Button;
			var label : String = clicked.label;

			if ( service && label ) service.sendButtonCommand ( label );
		}

		override protected function createUI () : void
		{
			super.createUI ( );

			buttons = [ b0 = new Button(), b1 = new Button(), b2 = new Button() ];

			addChild ( promptAnimator = new TitleText() );
			promptAnimator.move ( promptField.x, promptField.y );
			promptAnimator.setSize ( promptField.width, promptField.height );
			promptAnimator.literalTextFormat = promptField.getTextFormat();
			promptAnimator.literalTextFormat.align = "center";
			promptAnimator.textFormat = promptField.getTextFormat();
			promptAnimator.textFormat.align = "center";

			promptField.visible = false;

			addChild ( step1Animator = new TitleText() );
			step1Animator.center = false;
			step1Animator.move ( step1NotifyText.x, step1NotifyText.y );
			step1Animator.setSize ( step1NotifyText.width, step1NotifyText.height );
			var tf:TextFormat = step1NotifyText.getTextFormat();
			tf.align = "right";
			step1Animator.literalTextFormat = tf;

			step1NotifyText.visible = false;

			currentStep = STEP_1;

			cancelBtn.label = "CANCEL"
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.offFillColor = 0xBD0000; // red
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.enabled = false;
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, cancelTransaction, false, 0, true );

			if (model.host.disableAmex)
				amexLogo.visible = false;

			clear();

		}

		protected function cancelTransaction ( evt : MouseEvent ) : void
		{
			if ( service ) service.cancel();
		}

		override public function dispose ( ) : void
		{
			if ( service )
			{
				service.cancel();
				service.removeEventListener ( PinPadEvent.LOGON, onLoggedOn );
				service.removeEventListener ( PinPadEvent.DISPLAY, updateDisplay );
				service.removeEventListener ( PinPadEvent.CLEAR, clearDisplay );
				service.removeEventListener ( PinPadEvent.TRANSACTION, updateTransactionStatus );
				service.removeEventListener ( PinPadEvent.FAIL, handlePinPadError );
			}

			for ( var i : int = 0; i < buttons.length; i++ )
			{
				buttons[i].removeEventListener ( MouseEvent.CLICK, sendButtonCommand );
			}
		}

		protected function updateDisplay ( evt : PinPadEvent ) : void
		{
			displayData = evt.data;
		}

		protected function clearDisplay ( evt : PinPadEvent ) : void
		{
			clear();
		}

		protected function updateTransactionStatus ( evt : PinPadEvent ) : void
		{
			trace ( evt.data );

			Logger.log( "PIN Pad Transaction: " + (evt.data.Success.text() == "1" ? 'Successful' : 'Unsuccessful') + ' and ' + (evt.data.Authorized.text() == "1" ? 'Approved' : 'Declined'));

			// Log fatal errors
			if (evt.data.ReCo.substring(0,1) == 'Z' && evt.data.Authorized.text() != '1')
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( "159", { message : { reCo : evt.data.ReCo.text(), responseText : evt.data.ResponseText.text() } } ) ) );

			if ( (Environment.DEBUG && ConfigManager.get("dev") != null && ConfigManager.get("dev").approveAllCardPayments == "true") ||
					 (evt.data.Authorized.text() == "1" && evt.data.Success.text() == "1") )
			{

				var cart : XML = Model.getInstance().cart.getPrinterQueue();
				var cardType : String = "";
				var dpsTxnRef : String = evt.data.DpsTxnRef.text();
				if (Environment.DEBUG && ConfigManager.get("dev") != null && ConfigManager.get("dev").approveAllCardPayments == "true")
				{
					if (dpsTxnRef.length == 0)
						dpsTxnRef = 'Test';
					cardType = 'Test';
				}
				cart.appendChild ( <transactionRef>{dpsTxnRef}</transactionRef> );

				if (evt.data.CardType.text()+"" != "")
				{
					cardType = evt.data.CardType.text().toLowerCase();
					if (cardType == 'mastercard')
						cardType = 'master';
					else if (cardType == 'debit')
						cardType = 'eftpos'
					else if (cardType == 'amex')
						cardType = 'american_express'
				}
				if (cardType.length > 0)
					cart.appendChild ( <cardType>{cardType}</cardType> );
				// add surcharge card type as selected by the user
				if (model.cart.cardTypeSelected.length > 0)
					cart.appendChild ( <cardTypeSelected>{model.cart.cardTypeSelected}</cardTypeSelected> );

				var service : CardPrintingService = controller.checkout ( cart );
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL, showPrintingScreen, false, 0, true );
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_ERROR, showPaymentError, false, 0, true );

				return;

			}


			if ( evt.data.Authorized.text() == "0" )
			{
				dispatchEvent ( new PinPadEvent ( PinPadEvent.FAIL, evt.data ) );
				return;
			}

			switch ( evt.data.ResponseText.text().toString().toLowerCase() )
			{
				//case "TRANS CANCELLED" :
				//case "INCORRECT PIN" :
				case "ACCEPTED":
				{


					break;
				}

				case "busy" :
				case "card no. error" :
				case "trans cancelled" :
				{
					dispatchEvent ( new PinPadEvent ( PinPadEvent.FAIL, evt.data ) );
					break;
				}

				default:
				{
					View.getInstance().modalOverlay.hide();
					break;
				}
			}

		}

		protected function handlePinPadError ( evt : PinPadEvent ) : void
		{
			var errorMsg : String
			trace(evt.data);
			if (evt.data.toString().substr(7,4) == "2031") // socket error
				errorMsg = '151'
			else
				errorMsg = evt.data.toString()
			View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( errorMsg ) ) )	
			dispatchEvent ( new PinPadEvent ( PinPadEvent.FAIL, evt.data ) ); // Send event back to view to close overlay
		}

		protected function showPrintingScreen ( evt : CardPrinterServiceEvent ) : void
		{
			closeOverlay ( null );
			View.getInstance().currentScreenKey = View.PRINTING_SCREEN;
			TweenMax.delayedCall ( 1.5, controller.currentPrinterService.processNextCard );
		}

		protected function showPaymentError ( evt : CardPrinterServiceEvent ) : void
		{
			View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data ) ) )	
			closeOverlay(null);
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			dispose();
		}

		protected function onLoggedOn ( evt : PinPadEvent ) : void
		{
			service.processTransaction ( service.txnID, service.amount );
			cancelBtn.enabled = true;
		}

		public function set displayData ( d : XML ) : void
		{
			_displayData = d;
			render();
		}

		public function get displayData ( ) : XML
		{
			return _displayData;
		}

		override protected function render ( ) : void
		{
			if ( !displayData )
			{
				clear();
				return;
			}

			var replace : String = displayData.Text1.text().toLowerCase() == "accepted" && !service.loggedOn ? "PLEASE WAIT" : displayData.Text1.text();
				replace = replace.toLowerCase().indexOf ( "sig" ) > -1 ? "PLEASE WAIT" : replace;

		//	if ( currentStep == STEP_1 )
		//	{
				step1Animator.title = replace + "\n" + displayData.Text2.text();
		//	}
			//else
			//{
			//	step1Animator.title = "";
		///	}

			b0.label = displayData.Button1.text();
			b1.label = displayData.Button2.text();
			b2.label = displayData.Button3.text();

			b0.enabled = b0.label.length > 0;
			b1.enabled = b1.label.length > 0;
			b2.enabled = b2.label.length > 0;

			b0.enabled = b1.enabled = b2.enabled = false;

			b0.redraw();
			b1.redraw();
			b2.redraw();

			filterButtons();

			if ( displayData.Text1.text().toString().indexOf("Y/N") > -1 || displayData.Text2.text().toString().indexOf("Y/N") > -1 )
			{
				service.sendButtonCommand("Yes");
			}

			if ( displayData.Text1.text().toString() == "AWAITING ACCOUNT" )
			{
				currentStep = STEP_2;
			}
		}

		protected function filterButtons ( ) : void
		{
			var disallowed : Array = ["Manual"];

			for ( var i : int = 0; i < buttons.length; i++ )
			{
				if ( disallowed.indexOf ( buttons[i].label ) > -1 )
				{
					buttons[i].enabled = false;
				}
			}
		}

		public function show ( ) : void
		{
			TimeoutManager.lock();
		}

		public function hide ( ) : void
		{
			if ( service ) service.close();
		}

		override public function destroy ( ) : void
		{
			TimeoutManager.unlock(); // didn't work in hide
			this.dispose();
			View.getInstance().destroyPinPadOverlay();
		}

		public function clear ( ) : void
		{
		}


	}

}