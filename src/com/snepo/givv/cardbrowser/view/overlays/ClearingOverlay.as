package com.snepo.givv.cardbrowser.view.overlays
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
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
	import flash.net.*;
	import flash.utils.*;

	public class ClearingOverlay extends Component implements IOverlay
	{
		public static const USERNAME : String = 'clearing';
		public static const PASSWORD : String = '273';

		protected static const COINS : String = 'Clear Coins'
		protected static const NOTES : String = 'Clear Notes'

		protected var view : View;
		protected var timeoutTimer : Timer;
		protected var _name : String;
		protected var _clearingTitle : String;
		protected var _currencyType : String;
		protected var _processingAlert : Alert;

		public function ClearingOverlay( name : String )
		{
			view = View.getInstance();
			model = Model.getInstance();
			timeoutTimer = new Timer(10000);
			timeoutTimer.addEventListener( TimerEvent.TIMER, exit );
			_name = name.split('=')[1] || 'Anonymous Operator';

			super();
		}

		public function get canClose( ):Boolean
		{
			return true;
		}

		public function onRequestClose( ):void
		{

		}

		override protected function createUI( ) : void
		{
			super.createUI( );

			timeoutTimer.reset();
			timeoutTimer.start();

			var button : Array = new Array;
			var buttonIdx : int = 0;
			button[0] = firstBtn;
			button[1] = secondBtn;
			button[0].visible = button[1].visible = false;

			if (!model.host.disableCoins && model.host.kioskType != HostModel.KIOSK_TYPE_NOCOIN)
			{
				button[buttonIdx].label = COINS;
				button[buttonIdx].addEventListener( MouseEvent.CLICK, promptToClear );
				button[buttonIdx++].redraw();
			}
			if (model.host.paymentOption != HostModel.PAYMENT_OPTION_DISABLE_NOTES && model.host.kioskType != HostModel.KIOSK_TYPE_COINONLY)
			{
				button[buttonIdx].label = NOTES;
				button[buttonIdx].addEventListener( MouseEvent.CLICK, promptToClear );
				button[buttonIdx++].redraw();
			}
			if (buttonIdx == 0)
				TweenMax.delayedCall(0.1, exit);
			else if (buttonIdx == 1)
			{
				button[0].dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				TweenMax.delayedCall(0.1, exit);
			}
			else
				button[0].visible = button[1].visible = true

			exitBtn.label = "Exit";
			exitBtn.offFillColor = 0xBD0000; // red
			exitBtn.addEventListener( MouseEvent.CLICK, exit );
			exitBtn.redraw();
		}

		protected function promptToClear( evt : MouseEvent ) : void
		{
			_clearingTitle = (evt.target as Button).label;
			var message : String = "";
			switch (_clearingTitle)
			{
				case COINS:
					message = 'This will reset the COIN balance';
					_currencyType = ClearBalanceToken.COIN;
					break;
				case NOTES:
					message = 'This will reset the NOTE balance';
					_currencyType = ClearBalanceToken.NOTE;
					break;
				default:
					return;
			}
			var alert = Alert.show( { title : _clearingTitle, message : message, buttons : [ "OK", "CANCEL"], autoDismissTime : 20 } )
			view.addChild(alert);
			alert.addEventListener ( AlertEvent.DISMISS, onPromptToClearDismissed, false, 0, true );
		}

		protected function onPromptToClearDismissed( evt : AlertEvent )
		{
			timeoutTimer.reset();
			if (evt.reason == "OK")
			{
				Logger.log(_name + ' cleared the ' + _currencyType + ' balance.');
				// Clear balance with host
				_processingAlert = Alert.createMessageAlert ( "Processing...");
				view.addChild ( _processingAlert );
				verifyKioskAccount();
			}
			else
				exit();
		}

		protected function verifyKioskAccount ( ) : void
		{
			var mobile : String = model.host.customerMobile;
			var pin : String = model.host.customerPin;

			var verifyPinToken : VerifyPinToken = new VerifyPinToken();
			verifyPinToken.addEventListener ( TokenEvent.COMPLETE, onVerifiedKioskAccountSuccess, false, 0, true );
			verifyPinToken.addEventListener ( TokenEvent.ERROR, onVerifiedKioskAccountError, false, 0, true );
			verifyPinToken.start({ mobile : mobile, pin : pin });
		}

		protected function onVerifiedKioskAccountSuccess ( evt : TokenEvent ) : void
		{
			model.user.loginData = evt.data;
			clearBalance();
		}

		protected function onVerifiedKioskAccountError ( evt : TokenEvent ) : void
		{
			view.addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data )));
			exit();
		}

		protected function clearBalance ( ) : void
		{
			var token : ClearBalanceToken = new ClearBalanceToken();
			token.addEventListener ( TokenEvent.COMPLETE, onClearBalanceComplete, false, 0, true );
			token.addEventListener ( TokenEvent.ERROR, onClearBalanceError, false, 0, true );
			token.start( { currencyType : _currencyType, narrative : 'Clear Kiosk Balance by ' + _name } );
		}

		protected function onClearBalanceComplete ( evt : TokenEvent ) : void
		{
			if ( _processingAlert ) _processingAlert.dismiss();
			controller.printClearingReceipt( generateReceiptData(evt.data) );
			view.addChild( Alert.show( { title : 'Printing Receipt', message : 'Please collect the clearing receipt.', buttons : [ "OK" ], autoDismissTime : 10 } ));
			exit();
		}

		protected function onClearBalanceError ( evt : TokenEvent ) : void
		{
			if ( _processingAlert ) _processingAlert.dismiss();
			view.addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data ) ) );
			exit();
		}

		protected function exit( evt : Event = null ) : void
		{
			if ( _processingAlert ) _processingAlert.dismiss();
			timeoutTimer.reset();
			view.modalOverlay.hide();
		}

		protected function generateReceiptData ( totals : XML ) : Object
		{
			var message : String = "{cr}{left}\n"
			var totalChars : int = 45;

			message += "+--------------------------------------------+{cr}"
			message += "| {bold_on}Amt.{bold_off}   | {bold_on}Denomination{bold_off}          |   {bold_on}Total{bold_off}   |";
			message += "+--------------------------------------------+{cr}"

			var denominations : XMLList = totals..denomination;
			for ( var i : int = 0; i < denominations.length(); i++ )
			{
				var quantity : Number = Number (denominations[i].quantity.text() + "");
				var value : Number = Number (denominations[i].value.text() + "");

				var quantityPart : String = ( StringUtil.getPad ( 6 - (quantity+"").length) ) + quantity +  " x ";
				var valuePart : String = renderDollarsAndCents ( value, false );
				var lhs : String = "|" + quantityPart + "| " + valuePart;

				var totalPart : String = renderDollarsAndCents ( quantity * value, true );
				var spacesRequired : int = ( totalChars - lhs.length - 11);

				var rhs : String = StringUtil.getPad ( spacesRequired ) + "| " + totalPart;
				rhs = rhs + ( StringUtil.getPad(totalChars-lhs.length-rhs.length) ) + " |";

				message += lhs + rhs + "{cr}\n";
				if ( i < totals.perCoinValues.length - 1 ) message += "+--------------------------------------------+{cr}"
			}

			message += "+--------------------------------------------+{cr}";
			var totalLine : String = "GRAND TOTAL :";
			var total : String = renderDollarsAndCents ( totals.total, true );
			var rPadding : int = (10 - total.length);
			var lPadding : int = totalChars - totalLine.length - (total.length+rPadding+1);
			message += "| {bold_on}" + totalLine + StringUtil.getPad(lPadding) + total + StringUtil.getPad(rPadding) + "{bold_off} |{cr}";
			message += "+--------------------------------------------+{cr}";

			return { title : 'CLEARED ' + _currencyType.toUpperCase	() + 'S',
							 total : totals.total.text() + "",
							 exchange_id : totals.exchange_id.text() + "",
							 barcode : totals.exchange_id.text() + "",
							 date : StringUtil.getLongDate ( new Date() ),
							 time : StringUtil.getTime ( new Date() ),
							 operator : _name,
							 line_items : message };
		}

		protected function renderDollarsAndCents ( v : Number, fixed : Boolean ) : String
		{
			if ( !fixed )
			{
				if ( v >= 1 )
					return "$" + v;
				else
					return v.toFixed(2) + "c";
			}
			else
				return "$" + v.toFixed(2);
		}
	}
}