package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.services.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.control.*;
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
	import flash.net.*;

	public class CountingCoinsScreen extends Screen
	{
		public static const WAITING : String = "CountingCoinsScreen.WAITING";
		public static const STARTING : String = "CountingCoinsScreen.STARTING";
		public static const COUNTING : String = "CountingCoinsScreen.COUNTING";
		public static const CONVERTING : String = "CountingCoinsScreen.CONVERTING";

		protected var _state : String = '';
		protected var _card : Object = {};
		protected var _cardValue : Number = 0;
		protected var _coinValue : Number = 0;

		protected var totalsList : List;

		protected var reconnectCount : Number = 0;
		protected var counter : CoinSorterService;
		protected var currentValues : Object = {};
		protected var idleTimer : Timer;

		protected var convertCoinsOption : List;

		protected var finalizedResult : Object = {};
		protected var updateCoinBalanceToken : UpdateBalanceToken;
		protected var miniPromptAnimator : TitleText;

		protected var waitingAnimation : Loader;
		protected var countingAnimation : Loader;

		protected var completeOverlay : GenericMessageOverlay;
		protected var completeOverlayTimer : Timer;

		protected var _termsOverlay : CoinTermsOverlay = null;

		protected var dummyValues : Object = [ { denomination : 5, amount : 0 }, { denomination : 10, amount : 0 }, { denomination : 20, amount : 0 }, { denomination : 50, amount : 0 }, { denomination : 100, amount : 0 }, { denomination : 200, amount : 0 } ];


		public function CountingCoinsScreen ( )
		{
			super();

			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;

			_prompt = "";
			completeOverlayTimer = new Timer (6 * 1000);
			idleTimer = new Timer (30 * 1000); // catchall timeout of 30 seconds
			idleTimer.addEventListener ( TimerEvent.TIMER, promptToContinueCount );

			invalidate();
		}

		public function set state ( s : String ) : void
		{
			if ( state == s ) return;

			_state = s;

			applyState();
		}

		public function get state ( ) : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{
			var switchTime : Number = 1;

			switch ( state )
			{
				case WAITING :
				{
					startBtn.mouseEnabled = true;
					miniPromptAnimator.title = "Please drop your coins\nonto the kiosk coin tray.";

					TweenMax.to ( countingAnimation, switchTime, { autoAlpha : 0 } );
					TweenMax.fromTo ( coinAnim, switchTime, { x : 50, y : 210 - 50, autoAlpha : 0, immediateRender : true }, { y : 210, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.to ( waitingAnimation, switchTime, { autoAlpha : 1 } );
					TweenMax.fromTo ( roundMask, switchTime, { x : 50, y : 210 - 50, width : 440, height: 460, autoAlpha : 0, immediateRender : true }, { y : 210, autoAlpha : 1, ease : Quint.easeInOut } );

					TweenMax.fromTo ( startBtn, switchTime, { y : 352 - 50, autoAlpha : 0, immediateRender : true }, { y : 352, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.fromTo ( cancelBtn, switchTime, { y : 670 - 50, autoAlpha : 0, immediateRender : true }, { y : 670, autoAlpha : 1, ease : Quint.easeInOut } );

					TweenMax.to ( totalsList, switchTime, { y : 217 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( totalBox, switchTime, { y : 667 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( convertCoinsOption, switchTime, { y : 212 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( coinsFull, switchTime, { autoAlpha : 1 } );

					totalBox.convertEnabled = true;
					totalBox.enabled = false;

					if ( waitingAnimation.content ) ( waitingAnimation.content as MovieClip ).play();
					if ( countingAnimation.content ) ( countingAnimation.content as MovieClip ).stop();

					break;
				}

				case STARTING :
				{
					TimeoutManager.lock();

					miniPromptAnimator.title = "Please push your coins\ninto the left hand slot.";

					TweenMax.to ( waitingAnimation, switchTime, { autoAlpha : 0 } );
					TweenMax.to ( coinAnim, switchTime, { x : (View.APP_WIDTH / 2) - 224, y : 170, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.to ( countingAnimation, switchTime, { autoAlpha : 1, scaleX : 1.4, scaleY : 1.4 } );
					TweenMax.to ( roundMask, switchTime, { x : (View.APP_WIDTH / 2) - 224, y : 170, width : 448, height : 574, autoAlpha : 1, ease : Quint.easeInOut } );

					TweenMax.to ( startBtn, switchTime, { y : 352 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( cancelBtn, switchTime, { y : 670 + 50, autoAlpha : 0, ease : Quint.easeInOut } );

					TweenMax.to ( convertCoinsOption, switchTime, { y : 212 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( coinsFull, switchTime, { autoAlpha : 0 } );

					startBtn.mouseEnabled = false;
					TweenMax.delayedCall ( 1.5, startCoinsCounting );

					totalBox.enabled = false;

					if ( waitingAnimation.content ) ( waitingAnimation.content as MovieClip ).stop();
					if ( countingAnimation.content ) ( countingAnimation.content as MovieClip ).play();

					break;
				}

				case COUNTING :
				{
					Logger.log('Counting Coins.');
					miniPromptAnimator.title = "Please wait while your\ncoins are counted.";
					TweenMax.fromTo ( totalsList, switchTime, { y : 217 - 50, autoAlpha : 0, immediateRender : true }, { y : 217, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.fromTo ( totalBox, switchTime, { y : 667 - 50, autoAlpha : 0, immediateRender : true }, { y : 667, autoAlpha : 1, ease : Quint.easeInOut } );

					TweenMax.to ( coinAnim, switchTime, { x : 655, y : 210, ease : Quint.easeInOut } );
					TweenMax.to ( countingAnimation, switchTime, { autoAlpha : 1, scaleX : 1, scaleY : 1 } );
				  TweenMax.to ( roundMask, switchTime, { x : 657, y : 210, width : 320, height : 410, ease : Quint.easeInOut } );

					totalBox.convertEnabled = true;

					break;
				}

				case CONVERTING :
				{
					miniPromptAnimator.title = "Exchange product\noptions";

					TweenMax.to ( waitingAnimation, switchTime, { autoAlpha : 0 } );
					TweenMax.to ( countingAnimation, switchTime, { autoAlpha : 0 } );

					TweenMax.to ( coinAnim, switchTime, { autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( roundMask, switchTime, { autoAlpha : 0, ease : Quint.easeInOut } );

					TweenMax.to ( startBtn, switchTime, { y : 352 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( cancelBtn, switchTime, { y : 670 + 50, autoAlpha : 0, ease : Quint.easeInOut } );

					TweenMax.fromTo ( convertCoinsOption, switchTime, { y : 212 - 50, autoAlpha : 0, immediateRender : true }, { y : 212, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.to ( totalBox, switchTime, { y : 667 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( totalsList, switchTime, { y : 217 + 50, autoAlpha : 0, ease : Quint.easeInOut } );
					TweenMax.to ( coinsFull, switchTime, { autoAlpha : 0 } );

					totalBox.convertEnabled = false;
					totalBox.enabled = false;

					if ( waitingAnimation.content ) ( waitingAnimation.content as MovieClip ).stop();
					if ( countingAnimation.content ) ( countingAnimation.content as MovieClip ).stop();

					break;
				}
			}
		}

		protected function startCoinsCounting ( ) : void
		{
			Logger.log('Starting Count');
			reconnectCount = 0;
			counter = new CoinSorterService(true);
			counter.addEventListener ( CoinSorterServiceEvent.ERROR, checkCounterStatus, false, 0, true );
			counter.addEventListener ( CoinSorterServiceEvent.MACHINE_STATUS, checkCounterStatus, false, 0, true );
			counter.addEventListener ( CoinSorterServiceEvent.COUNTING_UPDATED, updateRunningTotals, false, 0, true );
			counter.addEventListener ( CoinSorterServiceEvent.COUNTING_FINALIZED, onCountingFinalized, false, 0, true );
			counter.addEventListener ( CoinSorterServiceEvent.COMMUNICATION_BREAKDOWN, onCommunicationBreakdown, false, 0, true );
			counter.connect();

			idleTimer.reset();
			idleTimer.start();
		}

		protected function checkCounterStatus ( evt : CoinSorterServiceEvent ) : void
		{
			idleTimer.reset();
			idleTimer.start();

			if ( evt.data.hasOwnProperty ( "errorState" ) )
			{
				var errorState : int = evt.data.errorState;

				if ( errorState != 0 )
					reportCoinSorterError ( errorState );
				else if ( evt.data.hasOwnProperty ( "counting" ) && !evt.data.counting )
					promptToContinueCount(null);
			}
		}

		protected function promptToContinueCount ( evt : TimerEvent ) : void
		{
			idleTimer.reset();
			Logger.log('Prompt to continue coin count');
			if ( state != COUNTING )
			{
				var alert : Alert = Alert.show ( { title : "You didn't put in any coins.\nDo you want to try again?", buttons : [ "TRY AGAIN", "I'M FINISHED"], autoDismissTime : 45 } );
    		alert.addEventListener ( AlertEvent.DISMISS, onConfirmContinueCount, false, 0, true );
    		addChild ( alert );
			}
			else
			{
				alert = Alert.show ( { title : "Have you finished?", buttons : [ "I'M FINISHED", "I HAVE MORE COINS"], autoDismissTime : 45 } );
    		alert.addEventListener ( AlertEvent.DISMISS, onConfirmContinueCount, false, 0, true );
    		addChild ( alert );
			}
		}

		protected function onConfirmContinueCount ( evt : AlertEvent ) : void
		{
			if ( evt.reason == "TRY AGAIN" || evt.reason == 'I HAVE MORE COINS' )
			{
				counter.start();
				idleTimer.start();
			}
			else
			if (state != COUNTING)
				Controller.getInstance().reset();
			else
				counter.end();
		}

		protected function reportCoinSorterError ( errorState : int ) : void
		{
			idleTimer.reset();

			var message : String;
			var severity : int;

			switch ( errorState )
			{
				case 1 :
				{
					message = "Printer 1 out of paper";
					severity = 10;
					break;
				}

				case 2 :
				{
					message = "Printer 2 out of paper";
					severity = 10;
					break;
				}

				case 3 :
				{
					message = "Error on printer 1";
					severity = 100;
					break;
				}

				case 4 :
				{
					message = "Error on printer 1";
					severity = 100;
					break;
				}

				case 5 :
				{
					message = "Maximum of 500 transactions reached";
					severity = 100;
					break;
				}

				case 6 :
				{
					message = "Overflow – maximum of amount reached";
					severity = 100;
					break;
				}

				case 7 :
				{
					message = "At least one full bag";
					severity = 100;
					break;
				}

				case 8 :
				{
					message = "Coins left in bowl";
					severity = 100;
					break;
				}

				case 9 :
				{
					message = "Railstop";
					severity = 100;
					break;
				}

				case 10 :
				{
					message = "Machine is turned on with an unfinished transaction";
					severity = 100;
					break;
				}

				case 11 :
				{
					message = "Bowl not closed";
					severity = 100;
					break;
				}

				case 12 :
				{
					message = "All bags are filled up";
					severity = 100;
					break;
				}

				case 13 :
				{
					message = "Check sensor";
					severity = 100;
					break;
				}

				case 14 :
				{
					message = "Sensor in right position";
					severity = 100;
					break;
				}

				case 15 :
				{
					message = "MASTER-error";
					severity = 100;
					break;
				}

				case 16 :
				{
					message = "HOST-error";
					severity = 100;
					break;
				}

				case 17 :
				{
					message = "Lost funnel position";
					severity = 100;
					break;
				}
			}
			Controller.getInstance().report ( severity, "Coin Counter Error = " + message );
			Logger.log( "Coin Counter Error = " + message, Logger.ERROR );
			View.getInstance().addChild ( Alert.show ( { title : "Coin Counter Error", message : message, buttons : [ "OK" ] } ) );
			var receiptData : Object = generateReceiptData ( currentValues );
			receiptData.exchange_id = '';
			receiptData.hasError = true;
			receiptData.barcode = '';
			receiptData.date = StringUtil.getLongDate ( new Date() );
			receiptData.time = StringUtil.getTime ( new Date() );
			controller.printCoinReceipt ( receiptData );
			Controller.getInstance().reset();
		}

		protected function onCommunicationBreakdown ( evt : CoinSorterServiceEvent ) : void
		{
			idleTimer.reset();

			Logger.log("Coin service reconnect due to error: " + evt.data.reason.text);
			reconnectCount += 1;
			if (reconnectCount <= 1)
				counter.reconnect();
			else
			if (reconnectCount == 2)
			{
				var errorMsg : String;
				trace(evt.data.reason.text)
				if (evt.data.reason.text.substr(7,4) == "2031") // socket error
					errorMsg = '152';
				else
					errorMsg = 	evt.data.reason.text;
				View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( errorMsg ) ) );
				View.getInstance().currentScreenKey = View.HOME_SCREEN;
			}
		}

		protected function updateRunningTotals ( evt : CoinSorterServiceEvent ) : void
		{
			if (evt.data.total > 0) state = COUNTING;

			var values : Object = evt.data.perCoinValues;
			values.sortOn ( "denomination", Array.NUMERIC | Array.DESCENDING );
			values.reverse();

			if ( values.length < totalsList.listItems.length )
			{
				Logger.log('Missing coin denominations from count update', Logger.ERROR);
				return;
			}

			for ( var i : int = 0; i < totalsList.listItems.length; i++ )
				totalsList.listItems[i].updateValues ( values[i] );

			totalBox.total = evt.data.total;
			this.currentValues = evt.data;
		}

		protected function addDummyCoin( evt : MouseEvent ):void
		{
			if (counter)
			{
	 			counter.removeEventListener ( CoinSorterServiceEvent.COUNTING_UPDATED, updateRunningTotals );
				counter.removeEventListener ( CoinSorterServiceEvent.COUNTING_FINALIZED, onCountingFinalized );
				counter.removeEventListener ( CoinSorterServiceEvent.COMMUNICATION_BREAKDOWN, onCommunicationBreakdown );
			}

			// Used for testing coin payments with out a coin mech
			var i : int;
			var total : Number = 0;
			var temp : String = evt.currentTarget.name.substr(6,1);
			var buttonId = Number (temp);
			if (buttonId >= 1 && buttonId <= 6)
			{
				dummyValues[buttonId - 1].amount += 1;

				for (i = 0; i < dummyValues.length; i++ )
					total += dummyValues[i].denomination * dummyValues[i].amount;
				var event : CoinSorterServiceEvent = new CoinSorterServiceEvent ( CoinSorterServiceEvent.COUNTING_UPDATED, { total : total, perCoinValues : dummyValues } );
				updateRunningTotals ( event );
			}
			else if (buttonId == 7)
			{
				for (i = 0; i < dummyValues.length; i++ )
					total += dummyValues[i].denomination * dummyValues[i].amount;
				event = new CoinSorterServiceEvent ( CoinSorterServiceEvent.COUNTING_FINALIZED, { total : total, perCoinValues : dummyValues } );
				onCountingFinalized( event )
			}
		}

		protected function onUpdatedBalance ( evt : TokenEvent ) : void
		{
			model.user.applyBalances ( evt.data.customer[0] );
			if (!completeOverlayTimer.running)
				onCompleteOverlayTimeout(null);
			else
				completeOverlayTimer.addEventListener ( TimerEvent.TIMER, onCompleteOverlayTimeout );
			updateCoinBalanceToken = null;
		}

		protected function onErrorUpdatingBalance ( evt : TokenEvent ) : void
		{
			var exchangeID : String = evt.target.response ? evt.target.response.exchange_id.text() + "" : "";

			var receiptData : Object = generateReceiptData ( finalizedResult );
				receiptData.exchange_id = exchangeID;
				receiptData.hasError = true;
				receiptData.barcode = receiptData.exchange_id;
				receiptData.date = StringUtil.getLongDate ( new Date() );
				receiptData.time = StringUtil.getTime ( new Date() );

			controller.printCoinReceipt ( receiptData );
			View.getInstance().addChild ( Alert.show ( ErrorManager.getErrorByCode ( evt.data ) ) );
			Controller.getInstance().reset();
		}

		protected function onCountingFinalized ( evt : CoinSorterServiceEvent ) : void
		{
			Logger.log('Finalising Count');
			updateRunningTotals ( evt );
			idleTimer.reset();

			finalizedResult = evt.data;
			state = CONVERTING;
			_coinValue = evt.data.total / 100;
			var belowMinValue : Boolean = model.host.minCartValue > 0 && _coinValue < model.host.minCartValue;

			// Build denomination array
			var denominations : Array = [];
			for (var i : int = 0; i < evt.data.perCoinValues.length; i++ )
				denominations.push( {value : evt.data.perCoinValues[i].denomination/100, quantity : evt.data.perCoinValues[i].amount} );

			// Send exchange to host
			updateCoinBalanceToken = new UpdateBalanceToken();
			updateCoinBalanceToken.addEventListener ( TokenEvent.ERROR, onErrorUpdatingBalance, false, 0, true );
			updateCoinBalanceToken.addEventListener ( TokenEvent.COMPLETE, onUpdatedBalance, false, 0, true );
			updateCoinBalanceToken.start ( {total : _coinValue, denominations : denominations} );

			// Show confirmation overlay
			completeOverlay = new GenericMessageOverlay();
			completeOverlay.okBtn.visible = false;
			var tf : TextFormat = completeOverlay.defaultTF;
			tf.size = 24;

			if (model.host.kioskType == HostModel.KIOSK_TYPE_COINONLY || belowMinValue)
			{
				// Set new coin balance before response from host for host card commission
				model.user.applyBalances( <customer><coin_amount>{_coinValue.toString()}</coin_amount></customer> );

				// Show host card
				var option : PrimaryCard = new PrimaryCard( true ); // hide button
				option.x = (completeOverlay.width / 2) - (option.width / 2);
				option.y = completeOverlay.contentField.y + 110;

				// Add charity card if value < min cart value
				if (belowMinValue)
				{
					completeOverlay.data = { title : "Charity Donation", message : "Your coin deposit was\nless than $" + model.host.minCartValue.toFixed(2) + "\nand will be donated to charity." };
					_card = model.cards.charityCards[0];
				}
				else
				{
					completeOverlay.data = { title : "Exchange Value", message : "Your total exchange value is displayed below." };
					_card = model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1,CardModel.EXCHANGE_CARD,CardModel.PRIMARY_CARD_1])[0];
				}
				option.data = _card;
				_cardValue = _coinValue - option.processingFee;
				completeOverlay.addChild( option );

				// exchange totals
				var cardExchangeValue : CoinBalanceBox = new CoinBalanceBox();
				cardExchangeValue.x = completeOverlay.contentField.x - 15;
				cardExchangeValue.y = option.y + option.height + 10;
				cardExchangeValue.title.text = "Card Exchange\nValue";
				cardExchangeValue.balanceField.text = "$" + _cardValue.toFixed(2);
				completeOverlay.addChild ( cardExchangeValue );
			}
			else
			{
				_card = null;
				_cardValue = 0;
				completeOverlay.data = { title : "Coin Deposit", message : "Your total coin deposit value is displayed below." };

				// exchange totals
				var coinDepositValue : CoinBalanceBox = new CoinBalanceBox();
				coinDepositValue.x = completeOverlay.contentField.x - 15;
				coinDepositValue.y = completeOverlay.contentField.y + 170;
				coinDepositValue.title.text = "Coin Deposit\nValue";
				coinDepositValue.balanceField.text = "$" + _coinValue.toFixed(2);
				completeOverlay.addChild ( coinDepositValue );
	  	}

			completeOverlay.defaultTF = tf;
			completeOverlay.okBtn.enabled = false;
			var spinner : MovieClip = new ModalMessage();
			spinner.messageField.text = "Processing...";
			spinner.messageField.width = spinner.messageField.textWidth + 5;
			spinner.messageField.height = spinner.messageField.textHeight + 5;
			spinner.x = completeOverlay.width / 2 - spinner.width / 2;
			spinner.y = completeOverlay.okBtn.y - 50;
			completeOverlay.addChild ( spinner );
 			View.getInstance().modalOverlay.currentContent = completeOverlay;
			completeOverlayTimer.removeEventListener ( TimerEvent.TIMER, onCompleteOverlayTimeout );
			completeOverlayTimer.reset();
			completeOverlayTimer.start();
			totalBox.enabled = true;
		}

		protected function onCompleteOverlayTimeout( evt : TimerEvent ) : void
		{
			completeOverlayTimer.reset();
			View.getInstance().modalOverlay.hide();

			if (_card != null)
				proceedToConfirmScreen();
			else
			{
				var primary : PrimaryCardSelector = new PrimaryCardSelector();
				primary.addEventListener ( Event.CLOSE, onPrimarySelectorClose, false, 0, true );
				primary.dataProvider = model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1,CardModel.PRIMARY_CARD_2,CardModel.EXCHANGE_CARD]).length > 0 ?
														 	 model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1,CardModel.PRIMARY_CARD_2,CardModel.EXCHANGE_CARD]) :
														 	 model.cards.hostPrimaryProducts([CardModel.TERTIARY_CARD_1]); // use teriery product if no others are provided.
				View.getInstance().modalOverlay.currentContent = primary;
			}
		}


		protected function onPrimarySelectorClose ( evt : Event ) : void
		{
			var primary : PrimaryCardSelector = evt.target as PrimaryCardSelector;
			primary.removeEventListener ( Event.CLOSE, onPrimarySelectorClose );
			View.getInstance().modalOverlay.hide();
			_card = primary.card;
			_cardValue = primary.cardValue;
			proceedToConfirmScreen();
		}

		protected function generateReceiptData ( totals : Object ) : Object
		{
			var message : String = "{cr}{left}\n"
			var totalChars : int = 45;

			message += "+--------------------------------------------+{cr}"
			message += "| {bold_on}Amt.{bold_off} | {bold_on}Denomination{bold_off}              |  {bold_on}Total{bold_off}  |";
			message += "+--------------------------------------------+{cr}"

			if ( totals.hasOwnProperty("perCoinValues") )
			{
				for ( var i : int = 0; i < totals.perCoinValues.length; i++ )
				{
					var line : Object = totals.perCoinValues[i];
					var amount : Number = line.amount;
					var denom : Number = line.denomination;

					var amountPart : String = ( StringUtil.getPad ( 4 - (amount+"").length) ) + amount +  " x ";
					var denomPart : String = renderDollarsAndCents ( denom, false );
					denomPart = denomPart + ( StringUtil.getPad ( 5 - denomPart.length ) ) + "=";

					var lhs : String = "|" + amountPart + "| " + denomPart;

					var totalPart : String = renderDollarsAndCents ( amount * denom, true );
					var spacesRequired : int = ( totalChars - lhs.length - 9); //totalPart.length );

					var rhs : String = StringUtil.getPad ( spacesRequired ) + "| " + totalPart;
					rhs = rhs + ( StringUtil.getPad(totalChars-lhs.length-rhs.length) ) + " |";

					message += lhs + rhs + "{cr}\n";
					if ( i < totals.perCoinValues.length - 1 ) message += "+--------------------------------------------+{cr}"
				}
			}

			message += "+--------------------------------------------+{cr}";
			var totalLine : String = "TOTAL EXCHANGE VALUE:";
			var total : String = renderDollarsAndCents ( (totals.hasOwnProperty("total") ? totals.total : 0), true );
			var padding : int = totalChars - totalLine.length - total.length - 2;
			message += "| {bold_on}" + totalLine + StringUtil.getPad(padding) + total + "{bold_off} |{cr}";
			message += "+--------------------------------------------+{cr}";

			return { line_items : message };
		}

		protected function renderDollarsAndCents ( v : Number, fixed : Boolean ) : String
		{
			if ( !fixed )
			{
				if ( v >= 100 )
					return "$" + ( v / 100 );
				else
					return v + "c";
			}
			else
				return "$" + ( v / 100 ).toFixed(2);
		}

		protected function reset() : void
		{
			for ( var i : int = 0; i < totalsList.listItems.length; i++ ) totalsList.listItems[i].updateValues ( { amount : 0 } );
			for ( i = 0; i < dummyValues.length; i++ ) dummyValues[i].amount = 0;
			startBtn.mouseEnabled = true;
			state = WAITING;
			totalBox.total = 0;
			_card = {};
			_coinValue = 0;
			_cardValue = 0;

			currentValues = {};
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild ( miniPromptAnimator = new TitleText() );
			miniPromptAnimator.move ( miniPromptField.x, miniPromptField.y );
			miniPromptAnimator.setSize ( miniPromptField.width, miniPromptField.height );
			miniPromptAnimator.literalTextFormat = miniPromptField.getTextFormat();
			miniPromptAnimator.title = "Please drop your coins\ninto the kiosk coin tray.";

			miniPromptField.visible = false;

			startBtn.offFillColor = 0x6c8e17; // green
			startBtn.useHtml = true;
			startBtn.label = "Pour your coins into the tray\n<font size=\"50\">PRESS HERE</font>\nto start counting";
			startBtn.helpIcon.visible = false;
			startBtn.applySelection();
			startBtn.redraw();
			startBtn.addEventListener ( MouseEvent.CLICK, startCount );

			DisplayUtil.startPulse( startBtn );

			cancelBtn.label = "CANCEL"
			cancelBtn.offFillColor = 0xBD0000; // Red
			cancelBtn.onLabelColor = 0xFFFFFF;
			cancelBtn.offLabelColor = 0xFFFFFF;
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, onCancel, false, 0, true );

			addChild ( totalsList = new List ( DenominationListItem ) );
			totalsList.setSize ( 550, 6 * 65 );
			totalsList.move ( coinAnim.x, coinAnim.y + 10 );
			totalsList.dataProvider = [ { denomination : 5 }, { denomination : 10 }, { denomination : 20 }, { denomination : 50 }, { denomination : 100 }, { denomination : 200 } ];
			totalsList.visible = false;
			totalsList.alpha = 0;

			totalBox.alpha = 0;
			totalBox.visible = false;
			totalBox.enabled = false;
			totalBox.total = 0;

			coinAnim.addChild ( waitingAnimation = new Loader() );
			coinAnim.addChild ( countingAnimation = new Loader() );
			coinAnim.mask = roundMask;

			waitingAnimation.visible = true;
			countingAnimation.visible = false;

			waitingAnimation.contentLoaderInfo.addEventListener ( Event.COMPLETE, onAnimationLoaded, false, 0, true );
			countingAnimation.contentLoaderInfo.addEventListener ( Event.COMPLETE, onAnimationLoaded, false, 0, true );

			var fLoader : ForcibleLoader = new ForcibleLoader(waitingAnimation);
			fLoader.addEventListener ( IOErrorEvent.IO_ERROR, onAnimationError, false, 0, true );
			fLoader.load ( new URLRequest ( "assets/videos/DropCoins.swf") );
			fLoader = new ForcibleLoader(countingAnimation);
			fLoader.addEventListener ( IOErrorEvent.IO_ERROR, onAnimationError, false, 0, true );
			fLoader.load ( new URLRequest ( "assets/videos/3StepsLoop.swf") );

			addChild ( convertCoinsOption = new List( ConvertCoinsButton ) );
			convertCoinsOption.defaultItemProperties = { width : 285, height : 203, multiline : true };
			convertCoinsOption.list.layoutStrategy = new GridFlowLayoutStrategy();
			convertCoinsOption.list.verticalSpacing = 22;
			convertCoinsOption.list.horizontalSpacing = 22;
			convertCoinsOption.setSize ( 926, 482  );
			convertCoinsOption.move ( 60, 212 );
			convertCoinsOption.visible = false;
			convertCoinsOption.alpha = 0;

			if ( Environment.isDevelopment && Environment.DEBUG )
			{
				tester1.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester2.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester3.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester4.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester5.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester6.addEventListener( MouseEvent.CLICK, addDummyCoin );
				tester7.addEventListener( MouseEvent.CLICK, addDummyCoin );
			}
			else
			{
				tester1.visible = false;
				tester2.visible = false;
				tester3.visible = false;
				tester4.visible = false;
				tester5.visible = false;
				tester6.visible = false;
				tester7.visible = false;
			}
		}

		protected function onCancel( evt : MouseEvent ) : void
		{
			Controller.getInstance().reset();
		}

		protected function onAnimationLoaded ( evt : Event ) : void
		{
			if ( evt.target.content ) ( evt.target.content as MovieClip ).stop();
		}

		protected function onAnimationError ( evt : ErrorEvent ) : void
		{
			Logger.log( "Error loading animation: " + evt.text, Logger.ERROR );
		}

		protected function proceedToConfirmScreen ( ) : void
		{
			var cart : CartModel = model.cart;
			var view : View = View.getInstance();
			var commObject : Object = model.partners.getCommissionAndFees ( _card.partnerID, CartModel.COINS );
			cart.paymentMethod = CartModel.COINS;
			// fake reviewed cart items
			var cardValue : Number = 0;
			var remainder : Number = _cardValue;
			var cardLimit : Number = model.host.maxCardValue;
			do
			{
				cardValue = Math.min( cardLimit, remainder );
				remainder = Math.max( 0, remainder - cardLimit );
				cart.addItem( { card : _card, amount : 1, perCard : cardValue, adjustedPerCard : cardValue,
												adjustedValue : ( (cardValue + commObject.fees ) / ( 1 - ( commObject.commission / 100 ) ) ), hasAdjustedValue : true,
												fee : commObject.fees,
												commission : commObject.commission,
					              entryMethod : AddCardsOverlay.PREDEFINED_VALUES } );
			} while ( remainder > 0 )

			view.currentScreenKey = View.CONFIRM_SCREEN;
		}

		protected function startCount ( evt : MouseEvent ) : void
		{
			state = STARTING;
		}

		protected function showTermsOverlay ( ) : void
		{
			_termsOverlay = new CoinTermsOverlay( ); // disable buttons if coin to card
			_termsOverlay.addEventListener ( Event.CLOSE, handleTermsOverlayClose, false, 0, true );
 			View.getInstance().modalOverlay.currentContent = _termsOverlay;
			verifyKioskAccount();
		}

		protected function handleTermsOverlayClose ( evt : Event ) : void
		{
			if ( ( evt.target as CoinTermsOverlay ).dismissReason != CoinTermsOverlay.OK )
				Controller.getInstance().reset();
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
			if (_termsOverlay != null) _termsOverlay.enableButtons();
			model.user.loginData = evt.data;
		}

		protected function onVerifiedKioskAccountError ( evt : TokenEvent ) : void
		{
			View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( evt.data )));//"150" ) ) );
			Controller.getInstance().reset();
		}


		override protected function onShow():void
		{
			model.cart.paymentMethod = CartModel.COINS;
			state = WAITING;
			showTermsOverlay();
		}

		override protected function onHide():void
		{
			reset();
			if ( counter )
			{
				counter.dispose();
				counter = null;
			}

			finalizedResult = null;
			TimeoutManager.unlock();
		}

	}
}