package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
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
	import flash.filters.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;

	public class BarcodeCardOverlay extends Component implements IOverlay
	{
		public static const ADD_CARD : String = "BarcodeCardOverlay.CHECKOUT";
		public static const BALANCE_CHECK : String = "BarcodeCardOverlay.BALANCE_CHECK";

		protected var keyBuffer : String = "";
		protected var status : TitleText;
		protected var barcode : BarcodeManager;
		protected var hasAlert : Boolean = false;
		protected var scanAlert : MovieClip;

		public var transientMaxValue : Object;
		public var mode : String = ADD_CARD;

		protected var processingAlert : Alert;
		protected var _upc, _cardNumber : String;
		protected static var _stage : Stage;
		protected static var processingBarcode : Boolean = false;

		public function BarcodeCardOverlay ( )
		{
			super();

			_width = 440;
			_height = 725;

			BarcodeManager.acceptingReads = true;
			barcode = BarcodeManager.getInstance();
			spinner.visible = false;
			spinner.alpha = 0;
			spinner.stop();
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			cancelBtn.label = "CANCEL"
			cancelBtn.offFillColor = 0xBD0000; // red
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			addChild ( status = new TitleText() );
			status.setSize ( 300, 60 );
			status.textFormat = { size : 26, align : "left", color : Environment.overlayTextColor };
			status.y = cancelBtn.y - 110;

			model.cards.addEventListener ( CardEvent.SELECTED_CARD_CHANGED, onSelectedCardChanged, false, 0, true );
		}

		public function captureSpecificCard() : void
		{
			trace('BarcodeCardOverlay - captureSpecificCard()')
			if (mode == BALANCE_CHECK)
			{
				promptField.text = "Check Balance\n\n";
				if (Environment.isLinx)
					promptField.appendText("Please scan your LINX card to check your card balance.");
				else
					promptField.appendText("Please scan your GiVV cash card or GiVV gift card to check your card balance.");
				barcode.addEventListener ( BarcodeEvent.SCAN, handleScanToCheckBalance, false, 100, true );
			}
			else
				barcode.addEventListener ( BarcodeEvent.SCAN, handleScanToAddCard, false, 100, true );
		}

		protected function handleScanToAddCard ( evt : BarcodeEvent ) : void
		{
			if (processingBarcode)
				return;

			processingBarcode = true;

			trace("BarcodeCardOverlay - handleScanToAddCard()")
//			if ( !transientMaxValue ) return;

			evt.stopImmediatePropagation();
			evt.preventDefault();

			var buffer : String = evt.data as String;

			if ( buffer.length == 12 )
			{
				trace("EAN barcode")
				var alert : Alert = Alert.show ( { title : "", message : "", autoDismissTime : 3 } );
					alert.addContent ( new IncorrectBarcodeAlert() );
					alert.width = alert.customContent.width + 20;
					alert.height = alert.customContent.height + 40;

				View.getInstance().addChild ( alert );

				processingBarcode = false;
				return;
			}
			else
			if ( buffer.length == 9 || buffer.length == 19 ) // emerchants/Indue
			{
				trace("eMerchants/Indue card. Performing host lookup....");
				_upc = buffer + "";
				_cardNumber = buffer + "";
				Logger.log("Scanned card from overlay: " + _cardNumber );
				// get card details from host
				processingAlert = Alert.createMessageAlert ( "Processing...");
				View.getInstance().addChild ( processingAlert );

				var token : CheckScannableToken = new CheckScannableToken();
				token.addEventListener ( TokenEvent.COMPLETE, onCheckScannableComplete, false, 0, true );
				token.addEventListener ( TokenEvent.ERROR, onCheckScannableError, false, 0, true );
				token.start ( buffer );
				return;
			}
			else
			if ( buffer.length == 16 )
			{
				// emerchants
				trace("eMerchants card. Performing PAN match...")
				_upc = buffer + "";
				_cardNumber = buffer + "";
			}else
			{
				// blackhawk
				trace("Blackhawk card. Performing UPC match...")
				_upc = buffer.substring ( 0, 11 );
				_cardNumber =  buffer + "";
			}

			var card : Object;
			if ( buffer.length > 1 )
				card = model.cards.lookupScannableCard ( _upc );

			processScannableCard( card );
			processingBarcode = false;
		}

		protected function onCheckScannableComplete ( evt : TokenEvent )
		{
			if (processingAlert) processingAlert.dismiss();
			processScannableCard( model.cards.getCardByID (evt.data.card.productid) );
			processingBarcode = false;
		}

		protected function onCheckScannableError ( evt : TokenEvent )
		{
			if (processingAlert) processingAlert.dismiss();
			var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( evt.data ) );
			View.getInstance().addChild ( alert );
			processingBarcode = false;
		}

		protected function processScannableCard ( card : Object )
		{
			if ( card == null || card != data )
			{
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( "107" ) ) );
			}
			else if (_cardNumber == "")
			{
				// trap errror where scannable card is added without a number
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( "123" ) ) );
			}
			else
			{
				var addCards : AddCardsOverlay = new AddCardsOverlay();
					addCards.scanData = { upc : _upc, cardNumber : _cardNumber };
					addCards.stepper.value = 1;
					addCards.stepper.visible = false;
					addCards.numOfCards.visible = false;

				View.getInstance().modalOverlay.currentContent = addCards;
			}
		}

		protected function handleScanToCheckBalance ( evt : BarcodeEvent ) : void
		{
			if (processingBarcode)
				return;

			processingBarcode = true;

			trace("BarcodeCardOverlay - handleScanToCheckBalance()")

			evt.stopImmediatePropagation();
			evt.preventDefault();

			TweenMax.to ( spinner, 0.5, { autoAlpha : 1 } );
			spinner.play();
			cancelBtn.enabled = false;
			var number : String = evt.data as String;
			// crack pan from swiped card
			if (number.split("=").length > 1)
				number = number.split("=")[0].substring(1, number.length);
			var token : CheckBalanceToken = controller.checkCardBalance( number );
			token.addEventListener ( TokenEvent.COMPLETE, onCheckBalanceComplete, false, 0, true );
			token.addEventListener ( TokenEvent.ERROR, onCheckBalanceError, false, 0, true );
		}

		protected function onCheckBalanceComplete ( evt : TokenEvent ) : void
		{
			processingBarcode = false;
			cancelBtn.enabled = true;
			TweenMax.to ( spinner, 0.5, { autoAlpha : 0, onComplete : spinner.stop } );

			var view : View = View.getInstance();
			var overlay : CheckBalanceOverlay = new CheckBalanceOverlay();
			overlay.data = evt.data;

			view.modalOverlay.currentContent = overlay
		}

		protected function onCheckBalanceError ( evt : TokenEvent ) : void
		{
			processingBarcode = false;
			status.temporaryTitle = "Invalid card...";
			status.x = (View.getInstance().modalOverlay.currentContent.width / 2) - (status.width / 2);

			trace ( "ERROR ==> " + evt.data );
			cancelBtn.enabled = true;

			TweenMax.to ( spinner, 0.5, { autoAlpha : 0, onComplete : spinner.stop } );
		}

		protected function onSelectedCardChanged ( evt : CardEvent ) : void
		{
			if ( model.cards.selectedCard.processas == CardModel.SCANNABLE )
			{
				data = model.cards.selectedCard;
			}else
			{
				var addOverlay : AddCardsOverlay = new AddCardsOverlay();
					addOverlay.data = model.cards.selectedCard;

				View.getInstance().modalOverlay.currentContent = addOverlay;
			}

		}

		override protected function render ( ) : void
		{
			super.render();
			promptField.text = "Please scan your\n" + model.cards.selectedCard.name + "\nto add to cart"
		}

		public function onRequestClose ( ) : void
		{

		}

		public function get canClose ( ) : Boolean
		{
			return true;
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
		}

		protected function processBuffer ( buffer : String ) : void
		{
		}

		protected function destroyAlert ( m : MovieClip ) : void
		{
			DisplayUtil.remove ( m );
			scanAlert = null;
			hasAlert = false;
		}


		override public function dispose ( ) : void
		{
			BarcodeManager.forceAccept = false;
			model.cards.removeEventListener ( CardEvent.SELECTED_CARD_CHANGED, onSelectedCardChanged );
			barcode.removeEventListener ( BarcodeEvent.SCAN, handleScanToAddCard );
			barcode.removeEventListener ( BarcodeEvent.SCAN, handleScanToCheckBalance );
			super.dispose ( );

		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{

			View.getInstance().modalOverlay.hide();
		}

	}

}