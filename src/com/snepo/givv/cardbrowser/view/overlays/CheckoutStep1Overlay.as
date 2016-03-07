package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.services.pinpad.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
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

	public class CheckoutStep1Overlay extends Component implements IOverlay
	{
		public static const CHECKOUT : String = "CheckoutStep1Overlay.CHECKOUT";
		public static const BALANCE_CHECK : String = "CheckoutStep1Overlay.BALANCE_CHECK";

		protected var keyBuffer : String = "";
		protected var status : TitleText;
		protected var swipe : SwipeManager;

		protected var isCheckingBalance : Boolean = false;

		public var mode : String = CHECKOUT;

		protected var pinPadService : PinPadService;

		public function CheckoutStep1Overlay ( )
		{
			super();

			_width = 440;
			_height = 725;

			SwipeManager.acceptingSwipes = true;
			swipe = SwipeManager.getInstance();
			swipe.addEventListener ( SwipeEvent.SWIPE, handleSwipe, false, 0, true );

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
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, cancelAndClose, false, 0, true );

			addChild ( status = new TitleText() );
			status.setSize ( 300, 60 );
			status.textFormat = { size : 26, align : "left" };
			status.y = cancelBtn.y + cancelBtn.height / 2 - 18;
			status.x = cancelBtn.x + cancelBtn.width - 10;

			if ( Environment.DEBUG ) addGesture ( new Gesture ( Gesture.SWIPE_UP, this, 0.3, simulateValidCardSwipe ) );

		}

		protected function cancelAndClose ( evt : MouseEvent ) : void
		{
			if ( pinPadService ) pinPadService.cancel();
			TweenMax.delayedCall ( 0.5, closeOverlay, [ null ] );
		}

		public function connectPinPad ( ) : void
		{
			if ( mode == BALANCE_CHECK )
			{
				titleField.text = "Check Balance";
				blurbField.text = "Please insert and remove your GiVV cash card or GiVV gift card to check your card balance.\n\nIt's best to check your balance before using your card.";
				blurbField.height = blurbField.textHeight + 5;
				cancelBtn.enabled = false;
				anim.y = 310;
			}

			pinPadService = new PinPadService(false);
			pinPadService.addEventListener ( Event.CONNECT, onPinPadConnect, false, 0, true );
			pinPadService.addEventListener ( PinPadEvent.READ, onPinPadRead, false, 0, true );
			pinPadService.connect();

		}

		protected function onPinPadConnect ( evt : Event ) : void
		{
			cancelBtn.enabled = true;
			pinPadService.startCustomRead();
		}

		protected function onPinPadRead ( evt : PinPadEvent ) : void
		{
			var track : String = evt.data.Track1.text();

			// Can only read track 1 as track 2 is masked
			track = track.split("=")[0];
			track = track.substring ( 1, track.length );
			if ( track.length > 3 )
			{
				processBuffer ( track );
			}
		}

		public function onRequestClose ( ) : void
		{
			if ( pinPadService ) pinPadService.close();
			pinPadService = null;
		}

		public function get canClose ( ) : Boolean
		{
			if ( mode == BALANCE_CHECK && isCheckingBalance ) return false;
			return true;
		}

		protected function simulateErrorCardSwipe ( g : Gesture ) : void
		{
			keyBuffer = "E";
			processBuffer( keyBuffer );
		}

		protected function simulateInvalidCardSwipe ( g : Gesture ) : void
		{
			keyBuffer = "12";
			processBuffer( keyBuffer );
		}

		protected function simulateValidCardSwipe ( g : Gesture ) : void
		{
			if ( mode == CHECKOUT )
			{
				keyBuffer = "{REDACTED}"; // This used to be hardcoded track2 data, but it was for a real card so it has to go.
			}else
			{
				keyBuffer = "{REDACTED}"; // This used to be a hardcoded credit card number, but it was for a real card so it has to go.
			}

			processBuffer( keyBuffer );
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );

		}

		protected function handleSwipe ( evt : SwipeEvent ) : void
		{
			processBuffer ( evt.buffer );
		}

		public function test ( buffer : String ) : void
		{
			processBuffer ( buffer );
		}

		protected function processBuffer ( buffer : String ) : void
		{
			if ( mode == BALANCE_CHECK )
			{
				performBalanceCheck ( buffer );
				SwipeManager.acceptingSwipes = false;
				return;
			}
		}

		override public function dispose ( ) : void
		{
			SwipeManager.acceptingSwipes = false;
			swipe.removeEventListener ( SwipeEvent.SWIPE, handleSwipe );
			super.dispose ( );

		}

		protected function performBalanceCheck ( number : String ) : void
		{
			if ( isCheckingBalance ) return;

			anim.stop();
			TweenMax.to ( anim, 1, { frame : 13 } );

			isCheckingBalance = true;

			TweenMax.to ( spinner, 0.5, { autoAlpha : 1 } );
			spinner.play();
			cancelBtn.enabled = false;

			var token : CheckBalanceToken = controller.checkCardBalance( number );
				token.addEventListener ( TokenEvent.COMPLETE, onCheckBalanceComplete, false, 0, true );
				token.addEventListener ( TokenEvent.ERROR, onCheckBalanceError, false, 0, true );

			trace ( "YEAH! " + number )	;
		}

		protected function onCheckBalanceComplete ( evt : TokenEvent ) : void
		{
			cancelBtn.enabled = true;
			TweenMax.to ( spinner, 0.5, { autoAlpha : 0, onComplete : spinner.stop } );

			isCheckingBalance = false;

			var view : View = View.getInstance();
			var overlay : CheckBalanceOverlay = new CheckBalanceOverlay();
				overlay.data = evt.data;

			view.modalOverlay.currentContent = overlay
		}

		protected function onCheckBalanceError ( evt : TokenEvent ) : void
		{
			anim.play();

			isCheckingBalance = false;
			status.temporaryTitle = "Invalid card...";

			trace ( "ERROR ==> " + evt.data );
			cancelBtn.enabled = true;

			TweenMax.to ( spinner, 0.5, { autoAlpha : 0, onComplete : spinner.stop } );

			if ( pinPadService ) pinPadService.startCustomRead();
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			if ( pinPadService ) pinPadService.close();
			pinPadService = null;
		}

	}
}
