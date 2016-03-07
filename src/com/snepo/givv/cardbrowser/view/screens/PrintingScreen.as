package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.services.*;
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

	public class PrintingScreen extends Screen
	{

		protected var queueList : List;
		protected var _currentHash : String;
		protected var _currentText : String;
		protected var itemsByHash : Object = {};

		protected var currentStack : PrinterCardStack;
		protected var stacksByHash : Object = [];
		protected var hashOrders : Array = [];
		protected var currentCardTitle : TitleText;
		protected var currentCardRates : TitleText;
		protected var stateText : TitleText;

		public var currentQueue : XML;
		protected var cardsPrinted : int = 0;
		protected var cardsToPrint : int = 0;

		public var printHasComplete : Boolean = false;
		protected var timeoutTimer : Timer;
		protected var initialTimeoutTimer : Timer;
		protected var overlayTimer : Timer;

		public function PrintingScreen ( )
		{
			super();

			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;

			timeoutTimer = new Timer (1000 * 90); // 1:30 with no state change
			timeoutTimer.addEventListener ( TimerEvent.TIMER, handleTimeout );
			initialTimeoutTimer = new Timer (1000 * 20); // 20 seconds for initial state change
			initialTimeoutTimer.addEventListener ( TimerEvent.TIMER, handleInitialTimeout );
			overlayTimer = new Timer (1000 * 10); // close overlay in 10 seconds
			overlayTimer.addEventListener ( TimerEvent.TIMER, onReceiptOverlayTimeout );
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			if (model.host.cardStock == HostModel.CARD_STOCK_PREPRINTED)
				instructionText.text = "Printing can take up to 10 seconds per card"
			else if (model.host.cardStock == HostModel.CARD_STOCK_DO_NOT_PRINT)
				instructionText.text = "";

			instructionText.y = 125;
			instructionText.x = (View.APP_WIDTH / 2) - (instructionText.width / 2)
			addChild ( instructionText );

			addChild ( queueList = new List( PrinterQueueItem ) );
			queueList.list.padding = 0;
			queueList.list.horizontalSpacing = 8;
			queueList.list.layoutStrategy = new HorizontalLayoutStrategy();
			queueList.list.verticalScrollEnabled = false;
			queueList.list.horizontalScrollEnabled = true;

			queueList.setSize ( 978, 96 );
			queueList.move ( 24, View.APP_HEIGHT - queueList.height - 30 );

			holders.addChild ( currentCardTitle = new TitleText() );
			currentCardTitle.setSize ( 500, 27 );
			currentCardTitle.redraw();
			currentCardTitle.textFormat = { size : 25, align : "left", font : Environment.font.fontName };
			currentCardTitle.textProperties = { multiline : false, wordWrap : false };
			currentCardTitle.center = false;
			currentCardTitle.x = 0;
			currentCardTitle.y = 170;

			holders.addChild ( currentCardRates = new TitleText() );
			currentCardRates.center = false;
			currentCardRates.textFormat = { size : 25, align : "left", font : Environment.font.fontName };
			currentCardRates.setSize ( 500, 27 );
			currentCardRates.x = 0;
			currentCardRates.y = 215;

			holders.addChild ( stateText = new TitleText() );
			stateText.setSize ( 195, 16 );
			stateText.move ( 444, 0 );
			stateText.textFormat = { font : Environment.font.fontName, size : 22, align : "center" };
		}

		public function processQueue ( ) : void
		{
			dispose();

			holders.completeField.text = "";

			if ( model.cart.cartItems.length < 1 )
			{
				View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( "103" ) ) );
				return;
			}

			var queue : XML = model.cart.getPrinterQueue( );
			queueList.dataProvider = model.cart.cartItems;

			for ( var i : int = 0; i < queueList.listItems.length; i++ )
			{

				var item : PrinterQueueItem = queueList.listItems[i];

				trace ( "adding " + item.hash + " to queue (" + item.data.card.processas + ")" );

				itemsByHash[ item.hash ] = item;
				stacksByHash[ item.hash ] = new PrinterCardStack();
				stacksByHash[ item.hash ].addEventListener ( Event.SELECT, updateTitleTexts, false, 0, true );
				stacksByHash[ item.hash ].offset = item.getBounds ( stacksByHash[ item.hash ] ) || new Rectangle();

				hashOrders.push ( item.hash );

				addChildAt ( stacksByHash[ item.hash ], 0 );
				stacksByHash[ item.hash ].x = 74;
				stacksByHash[ item.hash ].y = 265;
				stacksByHash[ item.hash ].data = item.data;
				stacksByHash[ item.hash ].visible = false;

			}

			DisplayUtil.top ( holders );

			for ( i = 0; i < hashOrders.length; i++ )
			{
				stacksByHash [ hashOrders[i] ].show();
			}

			stacksByHash [ hashOrders[0] ].startStack();

			initialTimeoutTimer.reset();
			initialTimeoutTimer.start();

			var service : CardPrintingService = controller.currentPrinterService;
				service.addEventListener ( CardPrinterServiceEvent.COMPLETE, onQueueComplete, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.STARTING_CARD, onStartingCard, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.CARD_FINISHED, onCardFinished, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.PROGRESS, onCardProgress, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.ERROR, showErrorOverlay, false, 0, true );
				service.addEventListener ( CardPrinterServiceEvent.STATE_CHANGE, updateStateText, false, 0, true );

			cardsToPrint = service.totalCards;
			cardsPrinted = 0;

			holders.completeField.text = "";

			this.currentQueue = queue;

		}

		public function testStateText ( list : Array = null ) : void
		{
			if ( !list ) list = [ "READING...", "TRANSFERRING...", "PRINTING...", "CONFIRMING..." ];
			if ( list.length )
			{
				var message : String = list.shift();
				stateText.title = message;

				TweenMax.delayedCall ( 2, testStateText, [ list ] );
			}
		}


		protected function updateStateText ( evt : CardPrinterServiceEvent ) : void
		{
			timeoutTimer.reset();
			timeoutTimer.start();
			initialTimeoutTimer.reset();
			initialTimeoutTimer.stop();

			switch ( evt.data )
			{
				case ConnectedCardProcessor.PRINTER_FEED_PENDING :
				{
					stateText.title = "FEEDING...";
					break;
				}

				case ConnectedCardProcessor.PRINTER_READ_PENDING :
				{
					stateText.title = "READING...";
					break;
				}

				case ConnectedCardProcessor.CARD_TRANSFER_PENDING :
				{
					stateText.title = "TRANSFERRING...";
					break;
				}

				case ConnectedCardProcessor.PRINTER_PRINT_PENDING :
				{
					stateText.title = "PRINTING...";
					if ( currentStack && currentStack.selectedCard )
					{
						TweenMax.to ( currentStack.selectedCard, model.host.printTime, { progress : 100, ease : Linear.easeNone } );
					}
					break;
				}

				case ConnectedCardProcessor.GATEWAY_CONFIRM_PENDING :
				{
					stateText.title = "CONFIRMING...";
					break;
				}

				case ConnectedCardProcessor.ACTIVATING :
				{
					stateText.title = "ACTIVATING...";
				}
			}

			holders.completeField.text = cardsPrinted + " of " + cardsToPrint;

		}

		protected function updateTitleTexts ( evt : Event ) : void
		{

			var nextStack : PrinterCardStack = evt.target as PrinterCardStack;
				nextStack.removeEventListener ( Event.SELECT, updateTitleTexts );

			var data : Object = nextStack.data;

			currentCardTitle.title = data.card.name;
			currentCardRates.title = data.amount + " @$" + data.adjustedPerCard.toFixed(2).replace(".00", "") + " = $" + ( data.amount * data.adjustedPerCard ).toFixed(2).replace(".00", "");
			currentCardTitle.textWidth = 500;

			holders.completeField.text = "0 of " + cardsToPrint;
		}

		override public function dispose ( ) : void
		{
			queueList.dispose();
			itemsByHash = {};
			hashOrders = [];
			_currentHash = null;

			if ( currentCardTitle ) currentCardTitle.clear();
			if ( currentCardRates ) currentCardRates.clear();

			holders.completeField.text = "";

			for each ( var stack : PrinterCardStack in stacksByHash )
			{
				stack.dispose();
				stack.destroy();
				stack = null;
			}

			stacksByHash = {};

			currentStack = null;
			stateText.title = "";

			if ( currentCardTitle ) currentCardTitle.title = "";
			if ( currentCardRates ) currentCardRates.title = "";

		}

		protected function showErrorOverlay ( evt : CardPrinterServiceEvent ) : void
		{
			timeoutTimer.reset();
			timeoutTimer.stop();

			if ( evt.data is String )
			{
				var overlay : GenericMessageOverlay = new GenericMessageOverlay();
					overlay.data = { title : "Card Printer Error", message : "There was an error printing your card. Please contact\nGiVV Customer Care.\n\n" + evt.data as String };
					overlay.addEventListener ( Event.CLOSE, handleCompleteOverlayClose, false, 0, true );

				Logger.log("Printing error: " + evt.data, Logger.ERROR);
				controller.report (50, "Printing error: " + evt.data);
				View.getInstance().modalOverlay.currentContent = overlay;
			}else
			{
				View.getInstance().addChild ( Alert.show ( evt.data ) );
				View.getInstance().currentScreenKey = View.CHOOSE_SCREEN;
			}
			controller.destroyPrintService();
			printHasComplete = true;

			TweenMax.to ( holders, 0.4, { autoAlpha : 0 } );
		}

		protected function onQueueComplete ( evt : CardPrinterServiceEvent ) : void
		{
			for each ( var stack : PrinterCardStack in stacksByHash )
			{
				stack.hide();
			}

			TweenMax.to ( advertising, 0.5, { scaleX : 0, scaleY : 0, ease : Back.easeIn } );

			timeoutTimer.reset();
			timeoutTimer.stop();

			overlayTimer.start();

			var guid : String = getGuid(10);
			model.cart.saveCart ( model.cart.cartItems, guid )
			controller.printReceipt ( { receipt_id : controller.currentPrinterService.refID, credit_card_number : controller.currentPrinterService.finalDigits, merchant_transaction_id : controller.currentPrinterService.currentTransactionID } );

			var overlay : GenericMessageOverlay = new GenericMessageOverlay();
				overlay.data = { title : "Thank you for\nusing " + Environment.companyName, message : "Please collect your receipt" };
				overlay.addEventListener ( Event.CLOSE, handleCompleteOverlayClose, false, 0, true );

			var image : MovieClip = new ReceiptImage();
				image.y = overlay.height - image.height;
				image.x = 0;

			overlay.addChild ( image );

			TweenMax.to ( holders, 0.4, { autoAlpha : 0 } );

			View.getInstance().modalOverlay.currentContent = overlay;
			controller.destroyPrintService();

			printHasComplete = true;

			controller.report ( 0, "Successful dispense cycle");
			TimeoutManager.unlock();

		}

		protected function onReceiptOverlayTimeout ( evt : TimerEvent ) : void
		{
			overlayTimer.reset();
			View.getInstance().modalOverlay.forceClose();
			controller.reset();
		}

		protected function getGuid ( len : int ) : String
		{
			var output : String = "";
			for ( var i : int = 0; i < len; i++ )
			{
				output += Math.floor ( Math.random() * 10 ) + "";
			}

			return output;
		}

		protected function handleCompleteOverlayClose ( evt : Event ) : void
		{
			overlayTimer.reset();

			var overlay : GenericMessageOverlay = evt.target as GenericMessageOverlay;
				overlay.removeEventListener ( Event.CLOSE, handleCompleteOverlayClose );

			controller.reset();
		}

		protected function showChooseScreen ( ) : void
		{
			View.getInstance().currentScreenKey = View.CHOOSE_SCREEN;
			dispose();
		}

		protected function onStartingCard ( evt : CardPrinterServiceEvent ) : void
		{
			var isNewHash : Boolean = _currentHash != evt.data.hash;
			_currentHash = evt.data.hash;

			trace ( "Starting card with hash: " + _currentHash );

			var item : PrinterQueueItem = itemsByHash[ _currentHash ];
				item.state = PrinterQueueItem.PROCESSING;

			if ( advertising.content.text == '' )
			{
				if ( item.data.advertisingMessage != null && item.data.advertisingMessage != '' )
				{
					// set text and show box
					_currentText = item.data.advertisingMessage;
					advertising.content.htmlText = _currentText;
					advertising.content.y = (advertising.content.height - advertising.content.textHeight) / 2;
					TweenMax.to ( advertising, 0.5, { scaleX : 1, scaleY : 1, ease : Back.easeOut } );
				}
			}
			else
			{
				if ( item.data.advertisingMessage != null && item.data.advertisingMessage != '' )
				{
					if ( item.data.advertisingMessage != _currentText )
					{
						// set text and animate change
						TweenMax.to ( advertising.content, 0.5, { scaleX : 0, scaleY : 0, ease : Back.easeOut } );
						_currentText = item.data.advertisingMessage;
						advertising.content.htmlText = _currentText;
						advertising.content.y = (advertising.height - advertising.content.textHeight) / 2;
						TweenMax.to ( advertising.content, 1, { scaleX : 1, scaleY : 1, ease : Back.easeIn, delay : 0.5 } );
					}
				}
				else
				{
					// set text and hide box
					advertising.content.htmlText = '';
					TweenMax.to ( advertising, 0.5, { scaleX : 0, scaleY : 0, ease : Back.easeIn } );
				}
			}
			if ( isNewHash )
			{
				currentStack = stacksByHash [ _currentHash ];
				currentStack.startStack();
			}
			currentStack.selectedIndex = evt.data.index;

			timeoutTimer.reset();
			timeoutTimer.start();
		}

		protected function onCardFinished ( evt : CardPrinterServiceEvent ) : void
		{
			var item : PrinterQueueItem = itemsByHash[ evt.data.hash ];
			var amount : int = item.data.amount - 1;

			if ( currentStack )
			{
				if ( currentStack.selectedCard )
				{
					TweenMax.killTweensOf ( currentStack.selectedCard );
				}

				currentStack.completeCardAt ( evt.data.index );
				DisplayUtil.top ( currentStack );
			}

			DisplayUtil.top ( holders );

			cardsPrinted++;
			holders.completeField.text = cardsPrinted + " of " + cardsToPrint;

			if ( evt.data.index >= amount )
			{
				item.state = PrinterQueueItem.COMPLETE;
				var nextIndex : int = hashOrders.indexOf ( evt.data.hash ) + 1;
				if ( nextIndex < hashOrders.length )
				{
					var nextStack : PrinterCardStack = stacksByHash [ hashOrders [ nextIndex ] ];
					if ( nextStack )
					{
						nextStack.startStack();
					}
				}
			}else
			{
				// More to go in this set
			}

		}

		protected function onCardProgress ( evt : CardPrinterServiceEvent ) : void
		{

		}

		override public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			_prompt = Environment.printingScreenPrompt;
			if ( model.cart.cartItems.length > 1) _prompt += "s"
			if ( holders && holders.completeField ) holders.completeField.text = "";
			if ( stateText ) stateText.title = "";
			if ( currentCardTitle ) currentCardTitle.title = "";
			if ( currentCardRates ) currentCardRates.title = "";

			super.show ( delay, notify );

			holders.alpha = 1;
			holders.visible = true;
			TweenMax.delayedCall ( delay + 0.3, processQueue );

			printHasComplete = false;

			advertising.scaleX = advertising.scaleY = 0;
			advertising.content.text = "";

			timeoutTimer.reset();
			timeoutTimer.start();

			TimeoutManager.lock();
		}

		override public function hide ( delay : Number = 0, notify : Boolean = true ) : void
		{
			super.hide ( delay, notify );
			TweenMax.delayedCall ( 1, dispose );

			timeoutTimer.reset();
			timeoutTimer.stop();
			initialTimeoutTimer.reset();
			initialTimeoutTimer.stop();

			printHasComplete = false;
		}

		protected function handleTimeout ( evt : TimerEvent ) : void
		{
			timeoutTimer.reset();
			timeoutTimer.stop();
		//	controller.report ( 60, "Printer hung at print screen." );
		//	controller.destroyPrintService();
		//	dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.ERROR, "Timeout during printing process" ) );
			var service : CardPrintingService = controller.currentPrinterService;
			var errorEvt : CardProcessorEvent = new CardProcessorEvent(CardPrinterServiceEvent.ERROR, "Timeout during printing process");
			service.onCardProcessorError(errorEvt);
		//	showErrorOverlay(new CardPrinterServiceEvent("Timeout",new String("Timeout during printing process")));
		//	controller.destroyPrintService();
		//	printHasComplete = true;
		}

		protected function handleInitialTimeout ( evt : TimerEvent ) : void
		{
			initialTimeoutTimer.reset();
			initialTimeoutTimer.stop();
		//	dispatchEvent ( new CardProcessorEvent ( CardProcessorEvent.ERROR, "Timeout connecting to printer" ) );
			var service : CardPrintingService = controller.currentPrinterService;
			var errorEvt : CardProcessorEvent = new CardProcessorEvent(CardPrinterServiceEvent.ERROR, "Timeout connecting to printer");
			Logger.log(errorEvt.data);
			service.onCardProcessorError(errorEvt);
		}
	}

}