package com.snepo.givv.cardbrowser.view.overlays
{
	/**
	* @author Andrew Wright
	*/

	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.note.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.adobe.serialization.json.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;

	public class NoteAcceptorOverlay extends Component implements IOverlay
	{
		public static const NOTES:String = "notes";
		public static const CARDS:String = "cards";

		public var dismissReason:String;

		protected var noteTotal:Number = 0;
		protected var cartTotal:Number = 0;

		protected var closing : Boolean = false;
		protected var unavailable : Boolean = false;

		protected var noteTotalAnimator:TitleText;
		protected var balanceAnimator:TitleText;
		protected var counter:NoteAcceptorService;

		protected var denominations:Array = [];
		protected var currentValues:Array = [];

		protected var inactivityTimer:Timer;

		protected var acceptedExchangeIDs:Array = [];
		protected var failedExchangeIDs:Array = [];

		protected var inactivityAlert:Alert;

		public var isSuperModal:Boolean = true;
		protected var updateBalanceAlert : Alert;

		public function NoteAcceptorOverlay( )
		{
			super();

			_width = 620;
			_height = 725;
		}

		public function onRequestClose( ):void
		{

		}

		public function get canClose( ):Boolean
		{
			return true;
		}

		public function createCounter( ):void
		{
			currentValues = [];
			denominations = [];
			failedExchangeIDs = [];
			acceptedExchangeIDs = [];

			unavailable = true;
			counter = new NoteAcceptorService();
			counter.addEventListener( NoteAcceptorEvent.STATE_CHANGE, onNoteAcceptorStateChange, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.GET_STATE, onNoteAcceptorGetState, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.GET_DENOMINATIONS, onNoteAcceptorGetDenominations, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.NOTE_ACCEPTED, onNoteAccepted, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.STARTED, onNoteAcceptorStarted, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.STOPPED, onNoteAcceptorStopped, false, 0, true );
			counter.addEventListener( NoteAcceptorEvent.UNAVAILABLE, onNoteAcceptorUnavailable, false, 0, true );
			counter.connect();

			startInactivityTimer();
		}

		public function cleanupCounter( ):void
		{
			stopInactivityTimer();

			if (counter && !unavailable)
				counter.stop();
			else if (unavailable && Environment.isDevelopment && Environment.DEBUG)
				updateCustomerBalance(); // just end if in debug and no note reader is attached
			else
				switchToConfirmScreen();
		}

		protected function startInactivityTimer( ):void
		{
			stopInactivityTimer();

			if (!closing)
			{
				inactivityTimer = new Timer(45000,1);
				inactivityTimer.addEventListener( TimerEvent.TIMER, promptForInactivity, false, 0, true );
				inactivityTimer.start();
			}
		}

		protected function stopInactivityTimer( ):void
		{
			if (inactivityTimer)
			{
				inactivityTimer.stop();
				inactivityTimer.removeEventListener( TimerEvent.TIMER, promptForInactivity );
				inactivityTimer = null;
			}
		}

		protected function promptForInactivity( evt : TimerEvent ):void
		{
			if (inactivityAlert)
			{
				return;
			}
			inactivityAlert = Alert.show({title:"",message:"You aren't putting any notes in.\nAre you finished?",
																		buttons:["I'M FINISHED","I'M STILL GOING"], autoDismissTime : Environment.SESSION_TIMEOUT});
			inactivityAlert.addEventListener( AlertEvent.DISMISS, handleInactivityPrompt, false, 0, true );

			View.getInstance().addChild( inactivityAlert );
		}

		protected function handleInactivityPrompt( evt : AlertEvent ):void
		{
			if (evt.reason == "I'M STILL GOING")
				startInactivityTimer();
			else
				closeOverlay(null);

			inactivityAlert = null;
		}



		protected function updateValues( key : int ):void
		{
			// Add value to key and calculate new total
			noteTotal = 0;
			for (var i : int = 0; i < currentValues.length; i++)
			{
				var item:Object = currentValues[i];
				if (item.key == key)
				{
					item.amount++;
					Logger.log('Note payment of $' + (currentValues[i].denomination/100).toString());
					Controller.getInstance().report(0, 'Note payment of $' + (currentValues[i].denomination/100).toString());
				}
				noteTotal += ( currentValues[i].denomination * currentValues[i].amount ) / 100;
			}

			// Update UI
			noteTotalAnimator.title = StringUtil.currencyLabelFunction ( noteTotal );
			if ( noteTotal < model.cart.commissionedTotal )
				balanceAnimator.title = StringUtil.currencyLabelFunction(model.cart.commissionedTotal - noteTotal);
			else
				balanceAnimator.title = "$0";

			cancelBtn.label = "I'M FINISHED";
			cancelBtn.offFillColor = Button.DEFAULT_OFFCOLOR;
			cancelBtn.applySelection();
			cancelBtn.redraw();

			// End if note balance is greater than cart total
			if (noteTotal >= cartTotal)
			{
				if (inactivityAlert)
				{
					DisplayUtil.remove( inactivityAlert );
					inactivityAlert = null;
				}
				closeOverlay(null);
			}
		}

		protected function printUpdateFailure( exchangeID : String, seed : Object ):void
		{
			var message:String = "";
			message +=  "{bold_on}Failed Exchange ID:{bold_off} ${exchange_id}{cr}\n";
			message +=  "{bold_on}Failed Amount:{bold_off} ${amount}{cr}\n{cr}\n{cr}Something went wrong. Please contact givv and quote the exchange id. \n{cr}\n{cr}\n{cr}\n{cr}";

			var keys : Object = { amount : seed.amount, kiosk_id : seed.kiosk_id, exchange_id : exchangeID, date : StringUtil.getLongDate ( new Date() ), time : StringUtil.getTime ( new Date() ) };

			message = StringUtil.replaceKeys(message,keys);

			Controller.getInstance().printMessage( message );
		}

		protected function onNoteAcceptorGetDenominations( evt : NoteAcceptorEvent ):void
		{
			this.denominations = evt.data.denominations;
			this.currentValues = [];

			for (var i : int = 0; i < denominations.length; i++)
			{
				var copy:Object = ObjectUtil.clone(denominations[i]);
				copy.denomination = copy.value * 100;
				copy.amount = 0;

				this.currentValues.push( copy );
			}

			counter.start();
		}

		protected function onNoteAccepted( evt : NoteAcceptorEvent ):void
		{
			var note:Object = evt.data;
			updateValues( note.key );

			startInactivityTimer();
		}

		protected function onNoteAcceptorStarted( evt : NoteAcceptorEvent ):void
		{
			unavailable = false;
		}

		protected function onNoteAcceptorStopped( evt : NoteAcceptorEvent ):void
		{
			counter.removeEventListener( NoteAcceptorEvent.STATE_CHANGE, onNoteAcceptorStateChange );
			counter.removeEventListener( NoteAcceptorEvent.GET_STATE, onNoteAcceptorGetState );
			counter.removeEventListener( NoteAcceptorEvent.GET_DENOMINATIONS, onNoteAcceptorGetDenominations );
			counter.removeEventListener( NoteAcceptorEvent.NOTE_ACCEPTED, onNoteAccepted );
			counter.removeEventListener( NoteAcceptorEvent.STARTED, onNoteAcceptorStarted );
			counter.removeEventListener( NoteAcceptorEvent.STOPPED, onNoteAcceptorStopped );
			counter.removeEventListener( NoteAcceptorEvent.UNAVAILABLE, onNoteAcceptorUnavailable );
			counter = null;
			updateCustomerBalance();
		}

		protected function onNoteAcceptorUnavailable( evt : NoteAcceptorEvent ):void
		{
			if ( (Environment.isDevelopment && Environment.DEBUG) )
			{
				if (currentValues.length == 0)
				{
					var denom:Object = {key:1,denomination:500,amount:0};
					this.currentValues.push( denom );
					denom = {key:4,denomination:5000,amount:0};
					this.currentValues.push( denom );
				}
			}
			else
			{
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( '158' ) ) );
				closeOverlay(null);
			}
		}

		protected function addDummyNote( evt : MouseEvent ):void
		{
			// Used for testing note payments with out a note reader
			if (evt.currentTarget == tester1)
				updateValues( 1 );
			else
				updateValues( 4 );
			startInactivityTimer();
		}

		protected function onNoteAcceptorStateChange( evt : NoteAcceptorEvent ):void
		{

		}

		protected function onNoteAcceptorGetState( evt : NoteAcceptorEvent ):void
		{

		}

		override protected function createUI( ):void
		{
			super.createUI( );
			closing = false;

			TimeoutManager.lock();

			createCounter();

			var tf:TextFormat = noteTotalField.getTextFormat();
			tf.size = 34;
			tf.align = "right";

			addChild( noteTotalAnimator = new TitleText() );
			noteTotalAnimator.center = false;
			noteTotalAnimator.move( noteTotalField.x, noteTotalField.y );
			noteTotalAnimator.setSize( noteTotalField.width, noteTotalField.height );
			noteTotalAnimator.literalTextFormat = tf;
			noteTotalAnimator.title = "$0";

			noteTotalField.visible = false;

			tf = remainingField.getTextFormat();
			tf.size = 34;
			tf.align = "right";

			addChild( balanceAnimator = new TitleText() );
			balanceAnimator.center = false;
			balanceAnimator.move( remainingField.x, remainingField.y );
			balanceAnimator.setSize( remainingField.width, remainingField.height );
			balanceAnimator.literalTextFormat = tf;

			remainingField.visible = false;

			cartTotalField.text = StringUtil.currencyLabelFunction(model.cart.commissionedTotal);
			cartTotal = model.cart.commissionedTotal;

			balanceAnimator.title = StringUtil.currencyLabelFunction(model.cart.commissionedTotal - model.user.noteBalance);

			if (model.user.noteBalance == 0)
			{
				cancelBtn.label = "CANCEL";
				cancelBtn.offFillColor = 0xBD0000; // red
				cancelBtn.applySelection();
				cancelBtn.redraw();
			}
			else
			{
				cancelBtn.label = "I'M FINISHED";
				cancelBtn.offFillColor = Button.DEFAULT_OFFCOLOR;
				cancelBtn.applySelection();
				cancelBtn.redraw();
			}
			cancelBtn.selected = false;
			cancelBtn.selectable = true;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener( MouseEvent.MOUSE_DOWN, closeOverlay, false, 0, true );

			cardTotalField.text = StringUtil.currencyLabelFunction(model.cart.total);
			feeTotalField.text = StringUtil.currencyLabelFunction(model.cart.commissionedTotal - model.cart.total);

			if ( Environment.isDevelopment && Environment.DEBUG )
			{
				tester1.visible = true;
				tester1.addEventListener( MouseEvent.CLICK, addDummyNote );
				tester2.visible = true;
				tester2.addEventListener( MouseEvent.CLICK, addDummyNote );
			}
			else
			{
				tester1.visible = false;
				tester2.visible = false;
			}
		}

		protected function closeOverlay( evt : MouseEvent ):void
		{
			if (!closing)
			{
				closing = true; // be careful not to close twice as two exchanges will be sent to the host

				trace('NoteAcceptorOverlay::closeOverlay()')
				cancelBtn.label = "Finishing...";
				cancelBtn.applySelection();
				cancelBtn.redraw();

				if (inactivityAlert)
				{
					DisplayUtil.remove( inactivityAlert );
					inactivityAlert = null;
				}

				// wait to see if more notes are coming before completing
				TweenMax.delayedCall( 3, cleanupCounter );
			};
		};


		protected function updateCustomerBalance( ) : void
		{
			if (closing) // only do this if this was triggered by closeOverlay
			{
				if (noteTotal == 0)
					onUpdateBalanceResponse( null );
				else
				{
					// Update host with note balance
					updateBalanceAlert = Alert.createMessageAlert ( "Processing...");
					View.getInstance().addChild ( updateBalanceAlert );

					// Build denomination array
					var denominations : Array = [];
					for (var i : int = 0; i < currentValues.length; i++ )
						denominations.push( {value : currentValues[i].denomination/100, quantity : currentValues[i].amount} );

					var updateNoteBalanceToken : UpdateBalanceToken = new UpdateBalanceToken();
					updateNoteBalanceToken.addEventListener( TokenEvent.COMPLETE, onUpdateBalanceResponse, false, 0, true );
					updateNoteBalanceToken.addEventListener( TokenEvent.ERROR, onUpdateBalanceError, false, 0, true );
					updateNoteBalanceToken.start( {total : noteTotal, denominations : denominations} );
				}
			}
		}

		protected function onUpdateBalanceResponse ( evt : TokenEvent ):void
		{
			if ( updateBalanceAlert ) updateBalanceAlert.dismiss();

			// save balance
			if (evt != null)
			{
				model.user.applyBalances( evt.data.customer[0] );
				acceptedExchangeIDs.push( evt.data.exchange_id.text() );
			}

			// go back to confirm screen
			switchToConfirmScreen();
		}

		protected function onUpdateBalanceError ( evt : TokenEvent ):void
		{
			var seed : Object = evt.target.seedData;
			var exchange_id : String;

			if ( updateBalanceAlert ) updateBalanceAlert.dismiss();
			if (evt.target.response != null && evt.target.response.hasOwnProperty('exchange_id'))
				exchange_id = evt.target.response.exchange_id.text() + "";
			else
				exchange_id = "Unknown";

			printUpdateFailure ( exchange_id, seed );
			View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( evt.data )));
			switchToConfirmScreen()
		}

		protected function switchToConfirmScreen()
		{
			// go back to confirm screen
			View.getInstance().modalOverlay.hide();

			var view:View = View.getInstance();
			view.currentScreenKey = View.CONFIRM_SCREEN;
			(view.getScreen ( View.CONFIRM_SCREEN ) as ConfirmScreen ).checkoutBtn.enabled = true;
			if (model.user.noteBalance == 0)
			{
				TimeoutManager.unlock();
				( view.getScreen ( View.CONFIRM_SCREEN ) as ConfirmScreen ).state = ConfirmScreen.REVIEW;
			}
			else
			{
				( view.getScreen ( View.CONFIRM_SCREEN ) as ConfirmScreen ).state = ConfirmScreen.CONFIRM;
			}
		}
	}
}