package com.snepo.givv.cardbrowser.view.overlays
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.services.*;
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
		
	public class LoginOverlay extends Component implements IOverlay
	{	

		public static const MOBILE_PHASE : String = "LoginOverlay.MOBILE_PHASE";
		public static const PIN_PHASE : String = "LoginOverlay.PIN_PHASE"
		public static const SUCCESS_PHASE : String = "LoginOverlay.SUCCESS_PHASE";
		public static const ERROR_PHASE : String = "LoginOverlay.ERROR_PHASE";

		public static const CREATE_IGNORE : String = "LoginOverlay.CREATE_IGNORE";
		public static const CREATE : String = "LoginOverlay.CREATE";
		public static const LOGIN  : String = "LoginOverlay.LOGIN";

		public var mode : String = CREATE;

		protected var keypad : Keypad;
		protected var loginPending : Boolean = false;
		protected var hasAlert : Boolean = false;
		protected var paymentAlert : MovieClip;
		protected var finished : Boolean = false;
		protected var promptAnimator : TitleText;
		protected var commandAnimator : TitleText;

		protected var _mobileNumber : String;
		protected var _pinNumber : String;
		protected var _emailAddress : String = null;
		protected var _preferredBank : String = null;

		protected var _state : String;
		protected var lastError : Object;

		public var response : Object = {};
		
		protected var submitBtnTween : TweenMax = null;

		public function LoginOverlay ( mode : String = null ) 
		{
			if ( mode != null )
			{
				this.mode = mode;
			}

			super();

			_width = 370;
			_height = 725;

		}

		public function set state ( s : String ) : void
		{
			if ( state == s ) return;

			_state = s;
			applyState();
		}

		public function get state () : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{
			switch ( state )
			{
				case MOBILE_PHASE :
				{
					commandAnimator.title = "Enter your mobile";
					if ( mode == CREATE )
					{
						promptAnimator.literalTextFormat.size = 17;
						promptAnimator.literalTextFormat.align = "left";

						promptAnimator.title = "A 6 digit code will be sent via SMS\n\nThis function is for credit/debit card security, authentication and Customer service if required.\n\nIf using the Coin Exchange it is used as account set up for future deposits."
					}else
					{
						promptAnimator.literalTextFormat.size = 26;
						promptAnimator.literalTextFormat.align = "center";
						promptAnimator.title = "Please enter your mobile number. An SMS activation code will be sent to your phone so you can proceed.";
					}
					keypad.value = "";
					keypad.isPassword = false;
					keypad.maxChars = 10;
					submitBtn.label = "CONTINUE";
					TweenMax.to ( resendBtn, 0.5, { autoAlpha : 0 } );
					

					break;
				}

				case PIN_PHASE :
				{
					commandAnimator.title = "Enter your PIN";

					promptAnimator.literalTextFormat.size = 26;
					promptAnimator.literalTextFormat.align = "center";
					promptAnimator.title = "Please enter the SMS Activation code sent to your mobile.";
					keypad.value = "";
					keypad.isPassword = true;
					keypad.maxChars = 6;
					submitBtn.label = "CONTINUE";

					DisplayUtil.top ( resendBtn );
					TweenMax.to ( resendBtn, 0.5, { autoAlpha : 1, delay : 1 } );

					break;
				}

				case SUCCESS_PHASE :
				{
					TweenMax.delayedCall ( 3, notifySuccess );
					submitBtn.enabled = false;
					cancelBtn.enabled = false;

					TweenMax.to ( resendBtn, 0.5, { autoAlpha : 0 } );
					break;
				}

				case ERROR_PHASE :
				{
					promptAnimator.title = lastError + "";
					TweenMax.delayedCall ( 3, revertToPinState );

					break;
				}
			}
		}

		protected function notifySuccess ( evt : Event = null ) : void
		{
			closeOverlay(null);
			dispatchEvent ( new LoginEvent ( LoginEvent.LOGIN, response ) ); 
		}

		protected function revertToPinState ( ) : void
		{
			if ( mode == CREATE_IGNORE )
			{
				dispatchEvent ( new LoginEvent ( LoginEvent.CREATE ) );
			}else if ( mode == CREATE )
			{
				state = MOBILE_PHASE;
			}else
			{
				state = PIN_PHASE;
			}
			
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );

			spinner.stop();
			spinner.alpha = 0;
			spinner.visible = false;
			spinner.scaleX = spinner.scaleY = 0;
			
			cancelBtn.label = "CANCEL"
			cancelBtn.offFillColor = 0xBD0000; // red
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, cancelLogin, false, 0, true );

			submitBtn.label = "CONTINUE"
			submitBtn.selected = false;
			submitBtn.selectable = false;
			submitBtn.offFillColor = 0x6c8e17; // green
			submitBtn.redraw();
			submitBtn.applySelection();
			submitBtn.enabled = false;
			submitBtn.addEventListener ( MouseEvent.MOUSE_DOWN, proceedByState, false, 0, true );

			addChild ( keypad = new Keypad() );
			keypad.labelFunction = function ( v : * ) : String { return v + "" };
			keypad.isPassword = false;
			keypad.defaultValue = "";
			keypad.value = keypad.defaultValue;
   			keypad.setSize ( 200, 300 );
   			keypad.move ( 370 / 2 - keypad.width / 2, 725 / 2 - keypad.height / 2 + 115 );
   			keypad.addEventListener ( Event.CHANGE, updateSubmitBtn );

   			addChild ( promptAnimator = new TitleText() );
   			promptAnimator.measureSize = false;
   			promptAnimator.textProperties = { multiline : true, wordWrap : true };
   			promptAnimator.move ( promptField.x, promptField.y );
   			promptAnimator.setSize ( promptField.width, promptField.height + 145 );
   			promptAnimator.literalTextFormat = promptField.getTextFormat();
   			promptAnimator.title = promptField.text;

   			addChild ( commandAnimator = new TitleText() );
   			commandAnimator.measureSize = false;
   			commandAnimator.move ( commandField.x, commandField.y );
   			commandAnimator.setSize ( commandField.width, commandField.height + 5 );
   			commandAnimator.literalTextFormat = commandField.getTextFormat();
   			commandAnimator.title = "";

   			resendBtn.label = "FORGOT PIN"
			resendBtn.selected = false;
			resendBtn.selectable = false;
			resendBtn.redraw();
			resendBtn.applySelection();
			resendBtn.alpha = 0;
			resendBtn.visible = false;
			resendBtn.y = promptAnimator.y + promptAnimator.height - 70;

			resendBtn.addEventListener ( MouseEvent.MOUSE_DOWN, resendPin, false, 0, true );

   			promptField.visible = false;
   			commandField.visible = false;

   			state = MOBILE_PHASE;

   			keypad.maxChars = 10;

   			removeAllGestures();

   			DisplayUtil.top ( resendBtn );
   						
		}

		public function onRequestClose ( ) : void
		{
			
			if ( canClose ) return;

			if ( hasAlert ) return;

		}

		protected function destroyAlert ( m : MovieClip ) : void
		{
			DisplayUtil.remove ( m );
			paymentAlert = null;
			hasAlert = false;
		}

		public function get canClose ( ) : Boolean
		{
			return !loginPending;
		}

		protected function updateSubmitBtn ( evt : Event ) : void
		{
			if ( loginPending ) 
			{
				submitBtn.enabled = false;
				return;
			}
			if ( state == MOBILE_PHASE )
			{
				submitBtn.enabled = ( keypad.value.length == keypad.maxChars ) && ( keypad.value.substring ( 0, 2 ) == "04" );	
			}else
			{
				submitBtn.enabled = ( keypad.value.length == keypad.maxChars );
			}
			
			if ( submitBtn.enabled )
			{
				if ( !submitBtnTween )
					submitBtnTween = DisplayUtil.startPulse( submitBtn );
			}
			else
			{
				DisplayUtil.stopPulse( submitBtnTween );
				submitBtnTween = null;
			}		
		}

		protected function proceedByState ( evt : MouseEvent ) : void
		{
			if ( state == MOBILE_PHASE )
			{
				sendMobileThenProceed();
			}else
			{
				sendPinThenProceed();
			}
		}

		protected function cancelLogin ( evt : MouseEvent ) : void
		{
			closeOverlay ( null );
			dispatchEvent ( new Event ( Event.CANCEL ) );
		}

		protected function sendMobileThenProceed ( ) : void
		{

			// This is only true when we're waiting for confirmation of the PIN
			//loginPending = true;

			showSpinner(true);			

			_mobileNumber = keypad.value;
			submitBtn.enabled = false;
			
			if ( mode == CREATE || mode == CREATE_IGNORE )
			{
				requestSMSToken();
			}else
			{
				showSpinner ( false );
				state = PIN_PHASE;
			}

		}

		protected function requestSMSToken ( resend : Boolean = false ) : void
		{
			var tokenData : Object = { mobile : _mobileNumber };

			if ( _emailAddress ) tokenData.email = _emailAddress;
			if ( _preferredBank ) tokenData.preferredBank = _preferredBank;

			var generatePinToken : GeneratePinToken = new GeneratePinToken();
				generatePinToken.resetting = resend;
				generatePinToken.addEventListener ( TokenEvent.COMPLETE, onGeneratedPin, false, 0, true );
				generatePinToken.addEventListener ( TokenEvent.ERROR, onGeneratedPinError, false, 0, true );
				generatePinToken.start( tokenData );
			
		}

		protected function resendPin ( evt : MouseEvent ) : void
		{
			showSpinner ( true );
			requestSMSToken ( true );
		}

		protected function onGeneratedPin ( evt : TokenEvent ) : void
		{
			showSpinner(false);

			if ( mode == CREATE_IGNORE )
			{
				dispatchEvent ( new LoginEvent ( LoginEvent.CREATE ) );
			}else
			{
				state = PIN_PHASE;
			}
		}

		protected function onGeneratedPinError ( evt : TokenEvent ) : void
		{
			showSpinner(false);

			if ( mode == CREATE_IGNORE )
			{
				// probably an existing account. Proceed as planned.
				dispatchEvent ( new LoginEvent ( LoginEvent.CREATE ) );
			}else
			{
				lastError = ErrorManager.getErrorByCode ( evt.data ).message;
				state = ERROR_PHASE;
			}
		}

		protected function requestPinConfirmation ( ) : void
		{
			// THis will make the server call to confirm
			// that the entered pin in correct;

			showSpinner(true);

			var verifyPinToken : VerifyPinToken = new VerifyPinToken();
				verifyPinToken.addEventListener ( TokenEvent.COMPLETE, onVerifiedPin, false, 0, true );
				verifyPinToken.addEventListener ( TokenEvent.ERROR, onVerifiedPinError, false, 0, true );
				verifyPinToken.start({ mobile : _mobileNumber, pin : keypad.value });

		}

		protected function onVerifiedPin ( evt : TokenEvent ) : void
		{
			this.response = evt.data;

			showSpinner(false);
			loginPending = false;

			notifySuccess();
		}

		protected function onVerifiedPinError ( evt : TokenEvent ) : void
		{
			lastError = ErrorManager.getErrorByCode ( evt.data ).message;
			state = ERROR_PHASE;

			showSpinner(false);
			loginPending = false;
		}

		protected function sendPinThenProceed ( ) : void
		{
			showSpinner ( true );

			loginPending = true;
			_pinNumber = keypad.value;

			requestPinConfirmation();
			submitBtn.enabled = false;
		}


		protected function showSpinner ( show : Boolean ) : void
		{
			TweenMax.killTweensOf ( spinner );
			if ( show )
			{
				TweenMax.to ( spinner, 0.3, { scaleX : 1, scaleY : 1, ease : Back.easeOut, autoAlpha : 1 } );
				spinner.play();
			}else
			{
				TweenMax.to ( spinner, 0.3, { scaleX : 0, scaleY : 0, ease : Back.easeIn, autoAlpha : 0, onComplete : DisplayUtil.hide, onCompleteParams : [ spinner ] } );
			}

			cancelBtn.enabled = !show;
		}

		protected function closeOverlay( evt : MouseEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			TimeoutManager.unlock();

			dispatchEvent ( new Event ( Event.CLOSE ) );
		}
		
	}
	
}