package com.snepo.givv.cardbrowser.view
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.pinpad.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.ui.*;
	import flash.system.*;

	public class View extends Component
	{
		public static const HOME_SCREEN : String = "View.HOME_SCREEN";
		public static const CHOOSE_SCREEN : String = "View.CHOOSE_SCREEN";
		public static const CONFIRM_SCREEN : String = "View.CONFIRM_SCREEN";
		public static const PRINTING_SCREEN : String = "View.PRINTING_SCREEN";
		public static const COUNTING_COINS_SCREEN : String = "View.COUNTING_COINS_SCREEN";
		public static const OOO_SCREEN : String = "View.OOO_SCREEN";
		public static const HOWTOJOIN_SCREEN : String = "View.HOWTOJOIN_SCREEN";
		public static const STAR_KEYBOARD_SCREEN : String = "View.STAR_KEYBOARD_SCREEN";
		public static const STAR_CLUB_ASSIST_SCREEN : String = "View.STAR_CLUB_ASSIST_SCREEN";
		public static const RESPONSIBLE_GAMBLING_SCREEN : String = "View.RESPONSIBLE_GAMBLING_SCREEN";

		public static const APP_WIDTH : int = 1024;
		public static const APP_HEIGHT : int = 768;

		/*protected*/public static var instance : View;

		public static function getInstance ( ) : View
		{
			instance ||= new View ( new Private() );
			return instance;
		}

		protected var _screens : Dictionary = new Dictionary();
		protected var _screenHolder : Sprite;
		protected var _currentScreen : Screen;
		protected var _currentScreenKey : String;

		public var modalOverlay : ModalOverlay;
		public var logo : MovieClip;
		public var title : TitleText;
		public var barcode : BarcodeManager;

		public var pinPadOverlay : PinPadOverlay;

		protected var processingAlert : Alert;
		protected var _upc, _cardNumber : String;
		protected static var _stage : Stage;
		protected static var processingBarcode : Boolean = false;
		protected var adminBarcode : String;

		public function View( p : Private )
		{
			super();

			if ( p == null ) throw new SingletonError ( "View" );

			_width = APP_WIDTH;
			_height = APP_HEIGHT;

		}

		public static function getStage() : Stage
		{
			return _stage;
		}

		public function showLogo ( show : Boolean ) : void
		{
			var scale : Number = show ? 1 : 0;
			var ease : Function = show ? Back.easeOut : Back.easeIn;
			var delay : Number = show ? 0.5 : 0;

			TweenMax.killTweensOf ( logo );
			TweenMax.to ( logo, 0.5, { scaleX : scale, scaleY : scale, ease : ease, delay : delay } );
		}

		public function startPinPadTransaction ( service : PinPadService ) : void
		{
			pinPadOverlay = new PinPadOverlay();
			pinPadOverlay.addEventListener ( PinPadEvent.FAIL, reinstateCheckoutBtnUponPinPadFail, false, 0, true );
			modalOverlay.currentContent = pinPadOverlay;
			pinPadOverlay.service = service;

		}

		public function destroyPinPadOverlay ( ) : void
		{
			if ( pinPadOverlay )
			{
				pinPadOverlay.removeEventListener ( PinPadEvent.FAIL, reinstateCheckoutBtnUponPinPadFail );
				pinPadOverlay = null;
			}
		}

		protected function reinstateCheckoutBtnUponPinPadFail ( evt : PinPadEvent ) : void
		{
			( getScreen ( CONFIRM_SCREEN ) as ConfirmScreen ).state = ConfirmScreen.REVIEW;
			( getScreen ( CONFIRM_SCREEN ) as ConfirmScreen ).checkoutBtn.enabled = true;
			modalOverlay.hide();
			destroyPinPadOverlay();

		}

		protected function registerScreen ( key : String, screen : Screen ) : void
		{
			removeScreen ( key );
			_screenHolder.addChild ( _screens [ key ] = screen );
			_screens [ key ].screenKey = key;
			screen.hideImmediately();
		}

		public function getScreen ( key : String ) : Screen
		{
			return _screens [ key ] || null;
		}

		protected function removeScreen ( key : String ) : void
		{
			if ( _screens [ key ] )
			{
				_screens [ key ].dispose();
				_screens [ key ].destroy();

				DisplayUtil.remove ( _screens[ key ] );

				delete _screens [ key ];
			}

		}

 		public function set currentScreen ( s : Screen ) : void
		{
			if ( s == currentScreen ) return;

			Logger.log ( "Changing screen from " + (currentScreen != null ? currentScreen.screenKey : "(none)") + " to " + s.screenKey );

			var oldScreen : Screen = currentScreen;
			if ( currentScreen ) currentScreen.hide();
			if ( modalOverlay ) modalOverlay.hide();

			_currentScreen = s;
			_currentScreen.show(0.4);

			_currentScreenKey = s.screenKey;

			title.title = currentScreen.prompt;

			dispatchEvent ( new ScreenEvent ( ScreenEvent.CHANGE, { newScreen : currentScreen.screenKey, oldScreen : ( oldScreen ? oldScreen.screenKey : null ) } ) );

			// TODO, have the screen say whether it needs a logo or not
			/*if ( currentScreen is HomeScreen ||
				   currentScreen is CountingCoinsScreen ||
			     currentScreen is OutOfOrderScreen ||
					 currentScreen is ConfirmScreen )
			{
				showLogo(false);

			}else
			{
				showLogo(true);

			}*/
			showLogo(false);
		}

		public function get currentScreen ( ) : Screen
		{
			return _currentScreen;
		}

		public function set currentScreenKey ( k : String ) : void
		{
			_currentScreenKey = k;
			currentScreen = _screens[k];
		}

		public function get currentScreenKey ( ) : String
		{
			return _currentScreenKey;
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );

			_stage = stage;
			registerScreen ( HOME_SCREEN	 		, new HomeScreen()			);
			registerScreen ( CHOOSE_SCREEN   		, new ChooseScreen()   		);
			registerScreen ( CONFIRM_SCREEN  		, new ConfirmScreen()  		);
			registerScreen ( PRINTING_SCREEN 		, new PrintingScreen() 		);
			registerScreen ( COUNTING_COINS_SCREEN	, new CountingCoinsScreen() );
			registerScreen ( OOO_SCREEN	 			, new OutOfOrderScreen()	);
			registerScreen ( HOWTOJOIN_SCREEN, new HowToJoinScreen() );
			registerScreen ( STAR_KEYBOARD_SCREEN , new StarKeyboardScreen() );
			registerScreen ( STAR_CLUB_ASSIST_SCREEN, new StarClubAssistScreen());
			registerScreen ( RESPONSIBLE_GAMBLING_SCREEN, new ResponsibleGamblingScreen());
			if (model.outOfOrder)
				currentScreenKey = OOO_SCREEN;
			else
				currentScreenKey = HOME_SCREEN;
			Logger.newline(2);
		}

		public function showSwipeOverlay ( ) : void
		{
			if ( Environment.FIRST_USER )
			{
				var overlay : SwipeGesture = new SwipeGesture();
					overlay.x = APP_WIDTH / 2;
					overlay.y = APP_HEIGHT / 2 - 50;
					overlay.alpha = 0;
					overlay.mouseEnabled = overlay.mouseChildren = false;

				addChild ( overlay );

				TweenMax.to ( overlay, 0.4, { scaleX : 3, scaleY : 3, alpha : 1, ease : Back.easeOut } );
				TweenMax.to ( overlay, 0.4, { scaleX : 0, scaleY : 0, alpha : 0, ease : Back.easeIn, delay : 3, onComplete : destroyGesture, onCompleteParams : [ overlay ] } );
			}

			Environment.FIRST_USER = false;
		}

		protected function destroyGesture ( s : MovieClip ) : void
		{
			s.stop();
			DisplayUtil.remove ( s );
			s = null;
		}

		public function reset ( ) : void
		{
			currentScreenKey = View.HOME_SCREEN;

			var chooseScreen : ChooseScreen = getScreen ( View.CHOOSE_SCREEN ) as ChooseScreen;
				chooseScreen.reset();

			if ( modalOverlay.currentContent ) modalOverlay.hide();
		}

		public function promptToRestoreSession ( ) : void
		{
			Logger.log("Session timeout prompt");
			var alert : Alert = Alert.show ( { title : "Session expiring", message : "Your session is about to expire.", buttons : [ "I'M STILL HERE", "I'M DONE"], autoDismissTime : 20 } );
			alert.addEventListener ( AlertEvent.DISMISS, onSessionPromptDismissed, false, 0, true );
			addChild ( alert );
		}

		protected function onSessionPromptDismissed ( evt : AlertEvent ) : void
		{
			switch ( evt.reason )
			{
				case "I'M STILL HERE" :
				{
					TimeoutManager.getInstance().start(Environment.SESSION_EXTENSION_TIMEOUT);
					break;
				}

				default :
				{
					if (!TimeoutManager.locked)
					{
						controller.reset();
						TimeoutManager.getInstance().start(Environment.SESSION_TIMEOUT);
					}
					break;
				}
			}
		}

		public function promptToRestart ( dismissTime : int = 5 ) : void
		{
			var alert : Alert = Alert.show ( { title : "Kiosk Restarting", message : "The kiosk is about to restart.", buttons : [ "I'M STILL HERE", "RESTART"], autoDismissTime : 5 } );
			alert.addEventListener ( AlertEvent.DISMISS, handleRestart, false, 0, true );
			addChild ( alert );
		}

		protected function handleRestart ( evt : AlertEvent ) : void
		{
			switch ( evt.reason )
			{
				case "I'M STILL HERE" :
				break;
			default :
				if (model.host.remoteControl == HostModel.REMOTE_CONTROL_UPGRADE_NOW ||
						model.host.remoteControl == HostModel.REMOTE_CONTROL_UPGRADE_OVERNIGHT)
					fscommand("exec", 'Upgrade.cmd');
				else
				if (model.host.remoteControl == HostModel.REMOTE_CONTROL_DOWNGRADE_NOW ||
						model.host.remoteControl == HostModel.REMOTE_CONTROL_DOWNGRADE_OVERNIGHT)
					fscommand("exec", 'Downgrade.cmd');

				fscommand("quit");
			}
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( _screenHolder = new Sprite() );
			addChild ( modalOverlay = new ModalOverlay() );
			modalOverlay.x = View.APP_WIDTH;

			addChild ( logo = new CompanyLogo() );
			logo.x = logo.width / 2 + 10;
			logo.y = logo.height / 2 + 10;
			logo.scaleX = logo.scaleY = 0;

			addChild ( title = new TitleText() );
			title.setSize ( View.APP_WIDTH, 70 );
			title.move ( 0, 60 );

			showLogo ( true );

			Logger.log ("View Created...");

/*
			addChild ( easterEgg = new EasterEgg() );
			easterEgg.x = View.APP_WIDTH / 2 - easterEgg.width / 2;
			easterEgg.y = 0//-easterEgg.height;
			easterEgg.modal.alpha = 0;
*/
			model.cart.addEventListener ( CartEvent.LIMIT_REACHED, onAddItemBreachesLimit, false, 0, true );
			model.cart.addEventListener ( CartEvent.MAX_CARDS_REACHED, onTooManyCardsInCart, false, 0, true );
			model.cart.addEventListener ( CartEvent.SCANNED_CARD_EXISTS, onScannedCardExists, false, 0, true );
			model.cart.addEventListener ( CartEvent.PAYMENT_METHOD_CHANGED, updateBalanceIndicator );

			barcode = BarcodeManager.getInstance();
			barcode.addEventListener ( BarcodeEvent.SCAN, handleBarcodeScan, false, 0, true );

			model.user.addEventListener ( UserEvent.BALANCE_CHANGED, updateBalanceIndicator );
			model.user.addEventListener ( UserEvent.JOINED, updateBalanceIndicator );
			model.user.addEventListener ( UserEvent.LEFT, updateBalanceIndicator );


			invalidate();
		}

		protected function updateBalanceIndicator ( evt : Event ) : void
		{
			try
			{
				var smallCart : SmallCart = ( getScreen ( CHOOSE_SCREEN ) as ChooseScreen ).smallCart;

				switch ( evt.type )
				{
					case UserEvent.BALANCE_CHANGED :
					{
						smallCart.balancePopOut.update();
						( getScreen ( CONFIRM_SCREEN ) as ConfirmScreen ).balancePopOut.update();

						break;
					}

					case UserEvent.JOINED :
					{
						break;
					}

					case UserEvent.LEFT :
					{
						( getScreen ( CONFIRM_SCREEN ) as ConfirmScreen ).hasBalance = false;
						smallCart.balancePopOut.expanded = false;
						smallCart.balancePopOut.update();
						smallCart.maxItems = 4;
						break;
					}

					case CartEvent.PAYMENT_METHOD_CHANGED :
					{
						smallCart.balancePopOut.update();
						( getScreen ( CONFIRM_SCREEN ) as ConfirmScreen ).balancePopOut.update();
						break;
					}
				}
			}catch ( e : Error )
			{

			}
		}

		protected function onScannedCardExists ( evt : CartEvent ) : void
		{
			addChild ( Alert.show ( ErrorManager.getErrorByCode ( "109" ) ) );
		}

		protected function onAddItemBreachesLimit ( evt : CartEvent ) : void
		{
			var cartLimit : Number;

			if ( evt.data != null )
			{
				cartLimit = Number ( evt.data )
			}else
			{
				cartLimit = model.host.maxCartValue;
			}

			if ( model.cart.paymentMethod == CartModel.COINS )
			{
				var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( "106", { message : { cart_limit : StringUtil.currencyLabelFunction ( cartLimit ) } } ) );
					alert.addEventListener ( AlertEvent.DISMISS, handleNotEnoughCreditAlert, false, 0, true );

				addChild ( alert );
			}else
			{
				addChild ( Alert.show ( ErrorManager.getErrorByCode ( "106", { message : { cart_limit : StringUtil.currencyLabelFunction ( cartLimit ) } } ) ) );
			}
		}

		protected function handleNotEnoughCreditAlert ( evt : AlertEvent ) : void
		{

		}

		protected function onTooManyCardsInCart ( evt : CartEvent ) : void
		{
			var maxCards : Number = model.host.maxCartCards;
			addChild ( Alert.show ( ErrorManager.getErrorByCode ( "105", { message : { max_cards : maxCards } } ) ) );
		}

		protected function checkForLoyalty ( buffer : String ) : Boolean
		{
			if (model.host.loyaltyEndpoint == '')
				return false;

			var loyaltyNumber : Number = Number ( buffer );
			var loyaltyMin : Number = model.host.loyaltyCardRangeStart;
			var loyaltyMax : Number = model.host.loyaltyCardRangeEnd;

			trace ( "loyaltyNumber: " + loyaltyNumber );
			trace ( "	min: " + loyaltyMin );
			trace ( "	max: " + loyaltyMax );

			if ( isNaN ( loyaltyNumber ) || isNaN ( loyaltyMin ) || isNaN ( loyaltyMax ) ) return false;

			var isLoyalty : Boolean = loyaltyNumber >= loyaltyMin && loyaltyNumber <= loyaltyMax;

			if ( isLoyalty )
			{
				var overlay : MarketPlaceOverlay;
				if ( modalOverlay.currentContent is MarketPlaceOverlay )
				{
					overlay = modalOverlay.currentContent as MarketPlaceOverlay;
					overlay.performScan ( buffer );
				}else
				{
					overlay = new MarketPlaceOverlay();
					modalOverlay.currentContent = overlay;
					overlay.performScan ( buffer );
				}
			}

			trace ( "	isLoyalty? " + isLoyalty );

			return isLoyalty;
		}

		protected function handleBarcodeScan ( evt : BarcodeEvent ) : void
		{
			if (processingBarcode)
				return;

			trace("View - handleBarcodeScan()")
			var buffer : String = evt.data + "";

			if (!modalOverlay.currentContent is BarcodeCardOverlay )
			{
				trace("View - handleBarcodeScan() is not going to handle this")
				return;
			}
			else
				processingBarcode = true;

			if ( buffer == AdminControlsOverlay.ADMIN_USERNAME ||
				   buffer == AdminControlsOverlay.OPERATOR_USERNAME ||
				   buffer.substr(0, ClearingOverlay.USERNAME.length) == ClearingOverlay.USERNAME )
			{
				adminBarcode = buffer;
				handleAdminBarcodeScan(evt);
				processingBarcode = false;
				return;
			}

			if ( currentScreenKey == OOO_SCREEN )
			{
				processingBarcode = false;
				return;
			}

			if ( checkForLoyalty( buffer ) )
			{
				processingBarcode = false;
				return;
			}

			if ( buffer.length == 12 )
			{
				trace("EAN barcode")
				var alert : Alert = Alert.show ( { title : "", message : "", autoDismissTime : 3 } );
					alert.addContent ( new IncorrectBarcodeAlert() );
					alert.width = alert.customContent.width + 20;
					alert.height = alert.customContent.height + 40;

				addChild ( alert );

				processingBarcode = false;
				return;
			}
			else
			if ( buffer.length == 9 || buffer.length == 19 ) // emerchants/Indue
			{
				trace("eMerchants/Indue card. Performing host lookup....");
				_upc = buffer + "";
				_cardNumber = buffer + "";
				Logger.log("Scanned card: " + _cardNumber );
				// get card details from host
				processingAlert = Alert.createMessageAlert ( "Processing...");
				addChild ( processingAlert );

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
				_cardNumber = buffer + "";
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
			addChild ( alert );
			processingBarcode = false;
		}

		protected function processScannableCard ( card : Object )
		{
			var overlay : ModalOverlay = modalOverlay;
			if ( card == null || card.name == "Unknown Card" )
			{
				addChild ( Alert.show ( ErrorManager.getErrorByCode ( "107" ) ) );
			}
			else if (_cardNumber == "")
			{
				// trap errror where scannable card is added without a number
				addChild ( Alert.show ( ErrorManager.getErrorByCode ( "123" ) ) );
			}
			else
			{
//				model.cards.selectedCard = card;
				var chooseScreen : ChooseScreen = getScreen ( View.CHOOSE_SCREEN ) as ChooseScreen;
				chooseScreen.selectedCard = card;
				trace( "Scanned card with data, ID=" + card.id + ", number=" + _cardNumber + ", upc=" + _upc);
				var addCards : AddCardsOverlay = new AddCardsOverlay();
					addCards.scanData = { upc : _upc, cardNumber : _cardNumber };
					addCards.stepper.value = 1;
					addCards.stepper.visible = false;
					addCards.numOfCards.visible = false;

				currentScreenKey = CHOOSE_SCREEN;

				overlay.currentContent = addCards;
			}
		}

		protected function handleAdminBarcodeScan ( evt : BarcodeEvent ) : void
		{
			var alert : Alert = Alert.show ( { title : "", message : "", buttons : ["CANCEL","OK"], autoDismissTime : 60 } );
				alert.addEventListener ( AlertEvent.DISMISS, handleAdminLogin, false, 0, true );

			var keypad : Keypad = new Keypad();
				keypad.isPassword = true;
				keypad.labelFunction = function ( v : Number ) : String { return (v==0 ? "" : v + "") };
				keypad.value = "";
				keypad.setSize ( 200, 300 );
				alert.addContent ( keypad );

			addChild ( alert );
		}

		protected function handleAdminLogin ( evt : AlertEvent ) : void
		{
			if ( evt.reason == "OK" )
			{
				var keypad : Keypad = ( evt.target as Alert ).customContent as Keypad;
				if ( (adminBarcode == AdminControlsOverlay.ADMIN_USERNAME && (keypad.value + "") == AdminControlsOverlay.ADMIN_PASSWORD) ||
		   			 (adminBarcode == AdminControlsOverlay.OPERATOR_USERNAME && (keypad.value + "") == AdminControlsOverlay.OPERATOR_PASSWORD) )
					modalOverlay.currentContent = new AdminControlsOverlay(adminBarcode);
				else if (adminBarcode.substr(0, ClearingOverlay.USERNAME.length) == ClearingOverlay.USERNAME && (keypad.value + "") == ClearingOverlay.PASSWORD)
					modalOverlay.currentContent = new ClearingOverlay(adminBarcode);
				else
				{
					trace(keypad.value)
					addChild ( Alert.show ( { title : "Error", message : "Invalid administrator password", buttons : ["OK"], delay : 0.6 } ) );
				}
			}
			adminBarcode = "";
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
		}
	}
}

class Private{}
