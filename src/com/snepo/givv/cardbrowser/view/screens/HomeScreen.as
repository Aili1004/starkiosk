package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
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
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;

	public class HomeScreen extends Screen
	{
		private static const BLUE_BUTTON   : int = 0;
		private static const YELLOW_BUTTON : int = 1;
		private static const RED_BUTTON :    int = 2;

		public var logo : MovieClip;
		public var blueButton : MovieClip;
		public var redButton : MovieClip;
		public var yellowButton : MovieClip;

		protected var boxes : Array = [];
		protected var balanceFooter : MovieClip;

		protected var view : View;

		public function HomeScreen ( )
		{
			super();

			view = View.getInstance();
			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;

			_prompt = "";

			invalidate();
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			if (model.loaded)
			{
				var drawnCount = 0;
				// First button - Yellow
				if (initHomeButton( BLUE_BUTTON, drawnCount ))
					drawnCount++;
				// Second button - Blue
				if (initHomeButton( YELLOW_BUTTON, drawnCount ))
					drawnCount++;
				// Third button - Red
				if (initHomeButton( RED_BUTTON, drawnCount ))
					drawnCount++;
			}
		}

		protected function initHomeButton ( buttonId : int, drawCount : int ) : Boolean
		{
			var selectBtnText : String = "SELECT";

			// Get button settings
			var buttonSettings : Object = model.host.getHomeButtonByPosition( buttonId );
			if (buttonSettings == null)
			{
				trace("HomeScreen::initHomeButton - Unable to find button settings (" + buttonId.toString() + ")");
				return false;
			}
			if (!buttonSettings.enabled)
				return false;

			// Customise button based on Id
			var button : MovieClip = new HomeBlueBox();

			var starHome : MovieClip = new StarHome();
			addChild(starHome);

			var swipeCardImg : MovieClip = new SwipeCardImg();
			addChild(swipeCardImg);

			starHome.HowToJoin.addEventListener ( MouseEvent.CLICK, showJoinPage );
			starHome.printCard.addEventListener ( MouseEvent.CLICK, goToMainPage );
			starHome.starAssist.addEventListener ( MouseEvent.CLICK, starAssistPage );

			switch (buttonId)
			{
				case BLUE_BUTTON:
				{
					/*addChild ( blueButton = button );
 					blueButton.infoBtn.footerField.textColor = Environment.blueButtonFooterColor;
 					blueButton.colorBtn.offFillColor = Environment.blueButtonColor;
 					blueButton.selectBtn.offFillColor = Environment.blueButtonSelectColor;
					blueButton.selectBtn.label = Environment.blueButtonSelectText;
					break;*/
				}
				case YELLOW_BUTTON:
				{
					/*addChild ( yellowButton = button );
					yellowButton.infoBtn.middleField.textColor = Environment.yellowButtonMiddleColor;
					yellowButton.infoBtn.footerField.textColor = Environment.yellowButtonFooterColor;
					yellowButton.colorBtn.offFillColor = Environment.yellowButtonColor;
					yellowButton.selectBtn.offFillColor = Environment.yellowButtonSelectColor;
					yellowButton.selectBtn.label = Environment.yellowButtonSelectText;
					break;*/
				}
				case RED_BUTTON:
				{
					/*addChild ( redButton = button );
					redButton.colorBtn.offFillColor = 0xCE001A;
					redButton.selectBtn.offFillColor = 0xCE001A;
					redButton.selectBtn.label = selectBtnText;
					break;*/
				}
				default:
				{
					trace("HomeScreen::initHomeButton - Invalid buttonId (" + buttonId.toString() + ")");
					return false;
				}
			}

			var visibleCount : int = model.host.visibleHomeButtonCount;
			button.x = ((View.APP_WIDTH / 2) - (((button.width * visibleCount) + (40 * (visibleCount-1))) / 2)) + // center all buttons
								  (button.width * drawCount) + (40 * drawCount); // offset this button within the button block

			button.y = 350;
			button.alpha = 0;
			button.autoResize(visibleCount, drawCount);
			if (visibleCount == 1)
			{
				/*logo.subtitle.text = 'Touch screen to start';
				selectBtnText = "START";*/
			}
			button.infoBtn.title = buttonSettings.title;
			button.infoBtn.description = buttonSettings.description;
			button.infoBtn.footer = buttonSettings.footer;
			if (buttonSettings.id == HostModel.BUTTON_HOME_PRIMARY_ID)
				button.infoBtn.cardImages = model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1,CardModel.PRIMARY_CARD_2]);
			else if (buttonSettings.id == HostModel.BUTTON_HOME_SECONDARY_ID)
				button.infoBtn.cardImages = model.cards.hostPrimaryProducts([CardModel.SECONDARY_CARD_1,CardModel.SECONDARY_CARD_2])
			else if (buttonSettings.id == HostModel.BUTTON_HOME_TERTIARY_ID)
			{
				var products : Array = model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1,CardModel.TERTIARY_CARD_2])
				if (buttonSettings.category <= 0 && products.length == 0)
					button.infoBtn.icon = new CoinExchangeIcon();
				else
					button.infoBtn.cardImages = model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1,CardModel.TERTIARY_CARD_2])
			}

			var corner : int = Environment.selectButtonCorner;
			button.selectBtn.cornerRadii = { tl : corner, tr : corner, bl : corner, br : corner };

			button.selectBtn.onFillColor = 0x6c8e17; // green
			button.selectBtn.iconPlacement = "right";
			var tf : TextFormat = new TextFormat();
			tf.font = Environment.buttonFont.fontName;
			tf.size = Environment.selectButtonFontSize;
			tf.letterSpacing = Environment.selectButtonFontLetterSpacing;
			button.selectBtn.textFormat = tf;
			button.selectBtn.label = button.selectBtn.label; // reapply text in new format
			button.selectBtn.refresh();
			button.selectBtn.icon = new RightArrowIcon();
			button.selectBtn.bottomHighlight.visible = false;
			button.selectBtn.applySelection();
			if (buttonSettings.id == HostModel.BUTTON_HOME_TERTIARY_ID && buttonSettings.category <= 0)
			{
				button.selectBtn.addEventListener ( MouseEvent.CLICK, showCoinExchange );
				button.bigBtn.addEventListener ( MouseEvent.CLICK, showCoinExchange );
			}
			else
			{
				button.selectBtn.addEventListener ( MouseEvent.CLICK, performFilter );
				button.bigBtn.addEventListener ( MouseEvent.CLICK, performFilter );
			}
			button.searchType = buttonSettings.category;
			button.colorBtn.redraw();
			button.selectBtn.redraw();
			boxes.push(button);

			return true
		}

		protected function showJoinPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.HOWTOJOIN_SCREEN;
		}

		protected function goToMainPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.CHOOSE_SCREEN;
		}

		protected function starAssistPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.STAR_CLUB_ASSIST_SCREEN;
		}

		protected function initFooterButtons ( ) : void
		{
			var tf : TextFormat = new TextFormat();
				tf.font = Environment.buttonFont.fontName;
				tf.size = 23;

			addChild ( balanceFooter = new BalanceFooter() );
			balanceFooter.y = View.APP_HEIGHT + 100;
			balanceFooter.alpha = 0;
			balanceFooter.x = 0;

			var corner : int = Environment.selectButtonCorner;
			var cornerRadii : Object = { tl : corner, tr : corner, bl : corner, br : corner };

			if (!model.host.buttons.balance.enabled)
				balanceFooter.balanceBtn.visible = false;
			else
			{
				balanceFooter.balanceBtn.offFillColor = 0x169CD4; // light blue
				balanceFooter.balanceBtn.onFillColor = 0x6c8e17; // green
				balanceFooter.balanceBtn.cornerRadii = cornerRadii;
				balanceFooter.balanceBtn.iconPlacement = "right";
				balanceFooter.balanceBtn.textFormat = tf;
				balanceFooter.balanceBtn.label = model.host.buttons.balance.title;
				balanceFooter.balanceBtn.icon = new RightArrowIcon();
				balanceFooter.balanceBtn.applySelection();
				balanceFooter.balanceBtn.labelField.x -= 10;
				balanceFooter.balanceBtn.addEventListener ( MouseEvent.CLICK, showCheckCardBalanceOverlay, false, 0, true );
				balanceFooter.balanceBtn.x = (View.APP_WIDTH / 2) - (balanceFooter.balanceBtn.width / 2);
			}

			balanceFooter.loyaltyBtn.visible = false;
			balanceFooter.photoBtn.visible = false;
		}

		protected function showLoyaltyOverlay ( evt : MouseEvent ) : void
		{
			var overlay : MarketPlaceOverlay = new MarketPlaceOverlay();

			view.modalOverlay.currentContent = overlay;
		}

		protected function showCheckCardBalanceOverlay ( evt : MouseEvent ) : void
		{
			var overlay : Component;

			if (Environment.isGivv)
			{
				// Use payment express card reader
				var swipeOverlay : CheckoutStep1Overlay;
				overlay = swipeOverlay = new CheckoutStep1Overlay();
				swipeOverlay.mode = CheckoutStep1Overlay.BALANCE_CHECK;
				swipeOverlay.connectPinPad();
			}
			else
			{
				// Use barcode reader / magstripe reader
				var barcodeOverlay : BarcodeCardOverlay;
				overlay = barcodeOverlay = new BarcodeCardOverlay();
				barcodeOverlay.mode = BarcodeCardOverlay.BALANCE_CHECK;
				barcodeOverlay.captureSpecificCard();
			}
			view.modalOverlay.currentContent = overlay;
		}

		protected function showCoinExchange ( evt : MouseEvent ) : void
		{
			if ( model.host.disableCoins )
				addChild ( Alert.show ( {title : "Coin Exchange Unavailable", message : model.host.disableCoinsReason, autoDismissTime : 5 } ));
			else
				view.currentScreenKey = View.COUNTING_COINS_SCREEN;
		}

		protected function performFilter ( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.CHOOSE_SCREEN;

			var choose : ChooseScreen = view.getScreen ( View.CHOOSE_SCREEN ) as ChooseScreen;
			choose.filterButtons.selectById ( int((( evt.currentTarget as Object ).parent as MovieClip).searchType) );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			/*logo.x = (View.APP_WIDTH / 2) - (logo.width / 2)	;
			logo.y = 5;*/
		}

		/*override public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			if ( isShown ) return;

			super.show ( delay, notify );

			logo.scaleX = logo.scaleY = 0;

			TweenMax.killDelayedCallsTo ( animateElementsOut );
			TweenMax.delayedCall ( 0.7, animateElementsIn );
			TimeoutManager.unlock();
		}

		override public function hide ( delay : Number = 0, notify : Boolean = true ) : void
		{
			if ( !isShown ) return;

			super.hide ( delay + 0.2, notify );

			TweenMax.killDelayedCallsTo ( animateElementsIn );
			animateElementsOut();
		}

		protected function animateElementsIn ( ) : void
		{
			TweenMax.to ( logo, 0.5, { scaleX : 1, scaleY : 1, ease : Back.easeOut } );
			for ( var i : int = 0; i < boxes.length; i++ )
			{
				TweenMax.to ( boxes[i], 0.7, { y : 250, alpha : 1, ease : Back.easeOut, delay : i / 10 } );
			}
			TweenMax.to ( balanceFooter, 0.8, { y : View.APP_HEIGHT - balanceFooter.height, alpha : 1, ease : Back.easeOut, delay : 0.2 } );
		}

		protected function animateElementsOut ( ) : void
		{
			TweenMax.to ( logo, 0.4, { scaleX : 0, scaleY : 0, ease : Back.easeIn } );
			if (model.loaded)
			{
				for ( var i : int = 0; i < boxes.length; i++ )
				{
					TweenMax.to ( boxes[i], 0.4, { y : 350, alpha : 0, ease : Back.easeIn, delay : i / 60 } );
				}
				TweenMax.to ( balanceFooter, 0.4, { y : View.APP_HEIGHT + 100, alpha : 0, ease : Back.easeIn, delay : 0.1 } );
			}
		}*/
	}
}
