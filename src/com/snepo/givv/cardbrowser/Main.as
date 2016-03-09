package com.snepo.givv.cardbrowser
{
	/**
	 * @author andrewwright
	 */

	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.services.note.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.greensock.easing.*;
	import com.greensock.*;

	import com.adobe.images.*;

	import flash.display.*;
	import flash.system.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.ui.*;

	public class Main extends Component
	{
		public var timeout:TimeoutManager;
		public var imageCache:ImageCache;
		public var config:ConfigManager;
		public var errors:ErrorManager;
		public var logger:Logger;
		public var view:View;

		public static var instance:Main;
		protected var spinner:MessageSpinner;//Spinner;
		protected var mouseVisible:Boolean = false;
		protected var startupTimer : Timer;

		public function Main( )
		{
			startupTimer = new Timer (1000 * 60);
			startupTimer.addEventListener ( TimerEvent.TIMER, onStartupTimeout );
			startupTimer.start();

			logger = new Logger();
			super();
			instance = this;

			Environment.init( stage );
			Alert.init( stage );
			BarcodeManager.init( stage );

			timeoutLocked.visible = false;

			addEventListener( Event.ENTER_FRAME, trackMemory, false, 0, true );

//			tester.addEventListener ( MouseEvent.CLICK, testBalance );

			addChild( logger );
			logger.log( "Company: " + Environment.companyName, Logger.LOG );
			logger.log( "Version: V" + Environment.VERSION, Logger.LOG );
			logger.log( "Operatoring System: " + Environment.operatingSystem, Logger.LOG);

			addChild( spinner = new MessageSpinner() );
			spinner.x = stage.stageWidth / 2;
			spinner.y = stage.stageHeight / 3;
			spinner.scaleX = spinner.scaleY = 0;

			// Load or generate password
			trace("Password = " + model.getPassword());
			if (model.getPassword() == null) // checked if shared object does not exist
			{
				// Shared object doesn't exist so create and store password
				model.createPassword();
				spinner.messageField.text = "Kiosk password is: " + model.getPassword();
			}
			else
			{
				errors = ErrorManager.init(stage);
				errors.addEventListener( Event.COMPLETE, onErrorsLoaded );
				errors.load( "data/errors.xml" );

				spinner.messageField.text = "Loading...";
			}
			InputManager.init( stage );

			TweenMax.to( spinner, 0.4, { scaleX : 2, scaleY : 2, ease : Back.easeOut } );

			stage.addEventListener( MouseEvent.MOUSE_DOWN, resetTimeout, false, 0, true );
			stage.addEventListener( KeyboardEvent.KEY_DOWN, handleKeyPress );
		}

		protected function handleKeyPress( evt : KeyboardEvent ):void
		{
			if (timeout)
			{
				timeout.reset();
			}
			if (evt.keyCode == Keyboard.F1)
			{
				screenGrab();
			}
			if (evt.keyCode == Keyboard.F2)
			{
				Logger.dump();
			}
			if (evt.keyCode == Keyboard.F3)
			{
				if (mouseVisible)
				{
					mouseVisible = false;
					Mouse.hide();
				}
				else
				{
					mouseVisible = true;
					Mouse.show();
				}
			}
			if (evt.keyCode == Keyboard.F4)
			{
				if (!model.loaded || view.currentScreenKey == View.HOME_SCREEN)
				{
					model.outOfOrder = true;
					view.currentScreenKey = View.OOO_SCREEN;
				}
				else if (view.currentScreenKey == View.OOO_SCREEN)
				{
					model.outOfOrder = false;
					view.currentScreenKey = View.HOME_SCREEN;
				}
			}
			if (evt.keyCode == Keyboard.F5 && !model.loaded)
			{
				showResetPasswordPrompt();
			}
			if (evt.keyCode == Keyboard.F11)
				view.modalOverlay.currentContent = new AdminControlsOverlay(AdminControlsOverlay.ADMIN_USERNAME);
			if (evt.keyCode == Keyboard.F12)
				view.promptToRestart();
		}

		protected function screenGrab( ):void
		{
			var imageName:String = StringUtil.getDateTime();
			imageName = imageName.replace(/\//g,"_");
			imageName = imageName.replace(/\:/g,"_");
			imageName = imageName.replace(" ","_");
			imageName +=  "_" + Math.round(Math.random() * 999999) + ".png";

			trace( imageName );

			var bd:BitmapData = new BitmapData(View.APP_WIDTH,View.APP_HEIGHT,true,0x00000000);
			bd.draw( this );

			var png:ByteArray = PNGEncoder.encode(bd);
			var file : FileReference = new FileReference();
			file.save(png, imageName);
		}

		protected function handleUncaughtErrors( evt : UncaughtErrorEvent ):void
		{

			if (evt.error is ErrorEvent)
			{
				logger.log( evt.text, Logger.ERROR );
			}
			else
			{
				logger.log( evt.error.getStackTrace(), Logger.ERROR );
			}

			if (Environment.DEBUG)
			{
				logger.show();
			}
		}

		protected function testBalance ( evt : MouseEvent ) : void
		{
			controller.checkCardBalance("123123123");
		}

		protected function enforceFullScreen( evt : FullScreenEvent ):void
		{
			if (!evt.fullScreen)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}

		protected function resetTimeout( evt : MouseEvent ):void
		{
			if (timeout)
			{
				timeout.reset();
			}
		}

		protected function handleConnect( evt : Event ):void
		{
			Logger.log( "Connected to swiper..." );
		}

		protected function onErrorsLoaded( evt : Event ):void
		{
			logger.log( "Errors loaded..." );
			logger.log( "Loading Configuration..." );
			spinner.messageField.text = "Loading Configuration...";
			config = ConfigManager.getInstance();
			config.addEventListener( ConfigEvent.CONFIG_READY, onConfigReady );
			config.addEventListener( ConfigEvent.CONFIG_ERROR, onConfigError );
			config.load( "data/config.xml" );
		}

		protected function trackMemory( evt : Event ):void
		{
			var mem:String = Number(System.totalMemory / 1024 / 1024).toFixed(2) + "MB";
			memField.text = Environment.KIOSK_UNIQUE_ID + " - " + "v" + Environment.VERSION + " - " + CardPrintingService.PAYMENT_ENDPOINT + " - " + mem;
		}

		protected function onConfigReady( evt : ConfigEvent ):void
		{
			logger.log( "Configuration Loaded..." );

			// Load debug setting from config and adjust UI
			Environment.DEBUG = ConfigManager.get("debugMode") == "true";
			logger.log( "Debug Mode: " + Environment.DEBUG, Logger.LOG );
			if (! Environment.DEBUG)
			{
				Mouse.hide();
				DisplayUtil.remove( memField );
				DisplayUtil.remove( timeoutLocked );
				stage.addEventListener( FullScreenEvent.FULL_SCREEN, enforceFullScreen );
			}
			else
				loaderInfo.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtErrors );

			// Load Heroku endpoint URL from config ;
			var OverrideEndpoint:String = ConfigManager.get("paymentEndpoint");
			if (OverrideEndpoint != null)
			{
				CardPrintingService.PAYMENT_ENDPOINT = OverrideEndpoint;
			}
			Logger.log( "Host Address: " + CardPrintingService.PAYMENT_ENDPOINT, Logger.LOG );

			// Load service host from config
			if (ConfigManager.get("dev") != null && ConfigManager.get("dev").serviceHost != null)
			{
				Environment.SERVICE =  ConfigManager.get("dev").serviceHost;
				Logger.log( "Service Host: " + Environment.SERVICE, Logger.LOG );
			}

			logger.log( "Loading model..." );
			spinner.messageField.text = "Loading Host Configuration...";
			model.addEventListener( ModelEvent.READY, onModelReady );
			model.addEventListener( ModelEvent.ERROR, onModelError );
			model.loadModel();
		}

		protected function onModelError( evt : ModelEvent ):void
		{
			//var Error : Object = ErrorManager.getErrorByCode(evt.data)
			startupTimer.reset();
			DisplayUtil.remove( spinner );
			spinner = null;
			addChild( view = View.getInstance() );
			view.currentScreenKey = View.OOO_SCREEN;
			TweenMax.delayedCall(10, view.promptToRestart, [30]);
		}

		protected function onModelReady( evt : ModelEvent ):void
		{
			logger.log( "Model Loaded..." );

			spinner.messageField.text = "Preparing Images...";
			logger.log( "Preparing Image Cache..." );
			imageCache = ImageCache.getInstance();
			imageCache.addEventListener( Event.COMPLETE, onImageCachePrepared );
			// TODO: Inject any other cachable images into the image cache here;
			imageCache.load();
		}

		protected function onImageCachePrepared( evt : Event ):void
		{
			startupTimer.reset();
			logger.log( "ImageCache prepared. Creating View...");
			spinner.messageField.text = "Startup Complete";
			TweenMax.delayedCall( 0.3, initView );
		}

		protected function showResetPasswordPrompt() : void
		{
			logger.hide();
			var alert : Alert = Alert.show ( { title : "Reset Kiosk Password", message : "Are you sure you want to reset the password?", buttons : [ "Yes", "NO" ], autoDismissTime : 5 } );
			alert.addEventListener ( AlertEvent.DISMISS, handleResetPassword, false, 0, true );
			addChild ( alert );
		}

		protected function handleResetPassword ( evt : AlertEvent ) : void
		{
			switch ( evt.reason )
			{
				case "Yes" :
					controller.report ( 500, "Kiosk password reset" );
					model.createPassword();
					addChild ( Alert.show ( {title : "Password Reset", message : "Kiosk password has been reset to: " + model.getPassword() } ));
					TweenMax.delayedCall(60, fscommand, ["quit"]);
					break;
				default :
					if (model.loaded)
						TweenMax.delayedCall( 0.3, fscommand, ["quit"]);
					else
						TweenMax.delayedCall( 0.3, initView );
			}
		}

		protected function initView( ):void
		{
			controller.testServices();
			DisplayUtil.remove( spinner );
			spinner = null;
			addChild( view = View.getInstance() );

			// load custom background
			background.loadImage(model.host.backgroundImage);

			// UI Profile validations
			if ( model.host.kioskType != HostModel.KIOSK_TYPE_NOCOIN )
			{
				if (model.host.primaryProducts.length == 0 ||
					 	(model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1])[0] != null && model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1])[0].processas != CardModel.PRINTABLE) ||
						(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0] != null && model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0].processas != CardModel.PRINTABLE) ||
						(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_2])[0] != null && model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_2])[0].processas != CardModel.PRINTABLE) ||
						(model.cards.hostPrimaryProducts([CardModel.EXCHANGE_CARD])[0] != null && model.cards.hostPrimaryProducts([CardModel.EXCHANGE_CARD])[0].processas != CardModel.PRINTABLE) )
				{
					view.currentScreenKey = View.OOO_SCREEN;
	  			view.addChild ( Alert.show ( ErrorManager.getErrorByCode ( "110" ) ) );
				}

				if ( model.cards.charityCards.length == 0 )
				{
					view.currentScreenKey = View.OOO_SCREEN;
	  			view.addChild ( Alert.show ( ErrorManager.getErrorByCode ( "111" ) ) );
				}
			}

			// Config validations
			if (Environment.companyName == null)
			{
				view.currentScreenKey = View.OOO_SCREEN;
				logger.log('Unknown company name for ' + stage.loaderInfo.url, Logger.ERROR);
				controller.report(100, 'Unknown company name for ' + stage.loaderInfo.url);
			}

			timeout = TimeoutManager.getInstance();
			timeout.start(Environment.SESSION_TIMEOUT);
			if (view.currentScreenKey == View.HOME_SCREEN)
				controller.reset();
		}

		protected function handleCloseOfPrimarySelector( evt : Event ):void
		{
			View.getInstance().modalOverlay.hide();
		}

		protected function onConfigError( evt : ConfigEvent ):void
		{
			logger.log( "No Config File ", Logger.LOG );
			onConfigReady(evt);
		}

		protected function onStartupTimeout( evt : TimerEvent )
		{
			logger.log ("Timeout on kiosk startup", Logger.FATAL);
			logger.show();
			addChild ( Alert.show ( {title : "Kiosk Restarting", message : 'Timeout during kiosk startup', autoDismissTime : 5 } ));
			TweenMax.delayedCall(15, fscommand, ["quit"]);
		}

		override protected function initStageEvents( evt : Event = null ):void
		{
			super.initStageEvents( evt );

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.fullScreenSourceRect = new Rectangle(0,0,View.APP_WIDTH,View.APP_HEIGHT);
			stage.displayState = StageDisplayState.FULL_SCREEN;
		}

	}
}