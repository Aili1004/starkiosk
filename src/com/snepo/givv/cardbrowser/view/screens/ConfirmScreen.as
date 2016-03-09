package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.services.tokens.*;
	import com.snepo.givv.cardbrowser.services.events.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.services.*;
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

	public class ConfirmScreen extends Screen
	{

		public static const REVIEW : String  = "ConfirmScreen.REVIEW";
		public static const PAY : String     = "ConfirmScreen.PAY";
		public static const CONFIRM : String = "ConfirmScreen.CONFIRM";

		public var cardList : List;
		protected var txnFee : TransactionFeeListItem;

		protected var totalPrice : Number = 0;
		protected var _displayPrice : Number = 0;
		protected var _estimatedPrice : Number = 0;
		protected var _confirmed : Boolean = false;

		protected var _state : String = REVIEW;
		protected var reviewAlert : Alert;
		protected var checkoutAlert : Alert;
		protected var verifyAlert : Alert;
		protected var _hasBalance : Boolean = false;
		protected var timeoutTimer : Timer;
		protected var _overlayTimer : Timer;
		protected var checkoutBtnTween : TweenMax = null;
		protected var _loyaltyCardCaptured : Boolean = false;

		public function ConfirmScreen()
		{
			super();

			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;
			_prompt = "Checkout now";

			timeoutTimer = new Timer (5 * 1000);
			timeoutTimer.addEventListener ( TimerEvent.TIMER, handleTimeout );
			_overlayTimer = new Timer (30 * 1000);
			_overlayTimer.addEventListener ( TimerEvent.TIMER, onOverlayTimeout );

			var orderNContact : MovieClip = new OrderNContact();
			addChild(orderNContact);
		}

		override public function get prompt ( ) : String
		{
			if (state == REVIEW)
			{
				var confirmOrderSteps : MovieClip = new ConfirmOrderSteps();
				addChild(confirmOrderSteps);
				var orderConfirmText : MovieClip = new OrderConfirmText();
				addChild(orderConfirmText);
				return "";
			}else
			if (state == PAY)
			{
				return "Confirm Payment";
			}else
			if (state == CONFIRM)
			{
				return "Final Confirmation";
			}else
				return "Confirm Payment";
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			model.cart.addEventListener ( CartEvent.COMMISSION_APPLIED, onCommissionApplied, false, 0, true );
			model.cart.addEventListener ( CartEvent.ITEM_REMOVED, onItemRemovedFromCart, false, 0, true );
			model.cart.addEventListener ( CartEvent.ITEM_UPDATED, onItemUpdated, false, 0, true );
			model.cart.addEventListener ( CartEvent.ITEM_ADDED, onItemAddedToCart, false, 0, true );
			model.cart.addEventListener ( CartEvent.DRAIN, onCartDrained, false, 0, true );

			emptyCartBtn.label = "BACK";
			emptyCartBtn.redraw();
			emptyCartBtn.offFillColor = 0xBD0000; // Red
			emptyCartBtn.applySelection();
			emptyCartBtn.addEventListener ( MouseEvent.MOUSE_DOWN, promptToEmptyCart );

			addChild ( cardList = new List() );
			cardList.list.layoutStrategy = new VerticalLayoutStrategy ( true, true );
			cardList.setSize ( 940, 440 ); //484
			cardList.addEventListener ( ListEvent.ITEM_INTERACTION, handleListItemInteraction );
			cardList.move ( 42, 160 );

			addChild ( txnFee = new TransactionFeeListItem() );
			txnFee.visible = false;
			txnFee.y = 600;
			txnFee.height = 55;

			checkoutBtn.label = "PROCESS";
			checkoutBtn.offFillColor = 0x0080ff;
			checkoutBtn.applySelection();
			checkoutBtn.hideButtonShadow();
			checkoutBtn.addEventListener ( MouseEvent.MOUSE_DOWN, handleReviewOrPrint );
			checkoutBtnEnabled = true;

			state = REVIEW;

		}

		public function set hasBalance ( h : Boolean ) : void
		{
			_hasBalance = h;
			applyHasBalance();
		}

		public function get hasBalance ( ) : Boolean
		{
			return _hasBalance;
		}

		protected function applyHasBalance ( ) : void
		{
			var xPos : Number;

			if ( hasBalance )
			{
				balancePopOut.expanded = true;
				balancePopOut.update();
				xPos = 332;
			}else
			{
				balancePopOut.expanded = false;
				balancePopOut.update();
				xPos = 462;
			}

		}

		public function set state ( s : String ) : void
		{
			this._state = s;
			this.applyState();
		}

		public function get state ( ) : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{
			var view : View = View.getInstance();

			if (view.currentScreenKey == View.CONFIRM_SCREEN)
				view.title.title = this.prompt;

			var model : Model = Model.getInstance();

			switch ( state )
			{
				case REVIEW :
				{
					_confirmed = false;
					trace('ConfirmScreen::applyState() - REVIEW');
					checkoutBtn.label = "PROCESS";
					checkoutBtn.applySelection();
					checkoutBtn.redraw();
					emptyCartBtn.visible = true;

					model.cart.removeAppliedChanges();

					break;
				}

				case PAY :
				{

					_confirmed = false;
					trace('ConfirmScreen::applyState() - PAY');
					checkoutBtn.label = "PAY NOW";
					checkoutBtn.applySelection();
					checkoutBtn.redraw();

					break;
				}

				case CONFIRM :
				{
					TimeoutManager.lock();
					trace('ConfirmScreen::applyState() - CONFIRM');
					checkoutBtn.label = "PRINT\nCARDS";
					checkoutBtn.applySelection();
					checkoutBtn.redraw();
					/*addCardsBtn.visible = false;*/
					emptyCartBtn.visible = false;

					if ( model.cart.paymentMethod == CartModel.NOTES )
					{
						// Check out if amount entered is equal to cart value
						if (model.user.applicableBalance == model.cart.commissionedTotal)
						{
							if (!_confirmed) startPrintingProcess();
						}
						else
						{
							if (model.user.applicableBalance > model.cart.commissionedTotal)
							{
								View.getInstance().addChild ( Alert.show ( {title : "Over Payment",
														 message :
														 "You have overpaid by " + StringUtil.currencyLabelFunction(model.user.applicableBalance - model.cart.commissionedTotal) + "\n\n" +
														 "This kiosk does not dispense change\n\n" +
														 "The extra value has been added to your card(s)",
												     	autoDismissTime : 5 } ));
								model.cart.adjustCartForOverPayment(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0], model.user.applicableBalance)
							}
							else
							{
								View.getInstance().addChild ( Alert.show ( {title : "Under Payment",
														 message :
														 "You have only paid " + StringUtil.currencyLabelFunction(model.user.applicableBalance) + "\n\n" +
														 "Your payment will be refunded\non a single gift card",
												     	 autoDismissTime : 5 } ));
								model.cart.adjustCartForUnderPayment(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0], model.user.applicableBalance)
							}
							model.cart.removeAppliedChanges();
							var token : ReviewCartToken = controller.review ( model.cart.getPrinterQueue(), true );
							token.addEventListener ( TokenEvent.COMPLETE, onReviewCartComplete, false, 0, true );
							token.addEventListener ( TokenEvent.ERROR, onReviewCartError, false, 0, true );
						}
					}
					else
					if ( model.cart.paymentMethod == CartModel.COINS )
					{
						if (!_confirmed) startPrintingProcess();
					}
					_confirmed = true;
					break;
				}
			}
			updateTotal();
		}

		protected function promptToEmptyCart ( evt : MouseEvent ) : void
		{
			var alert : Alert = Alert.show ( { title : "Are you sure?", message : "Are you sure you want to cancel your order?", buttons : ["YES", "NO" ] } );
				alert.addEventListener ( AlertEvent.DISMISS, handleEmptyCartPrompt, false, 0, true );

			View.getInstance().addChild ( alert );
		}

		protected function handleEmptyCartPrompt ( evt : AlertEvent ) : void
		{
			if ( evt.reason == "YES" )
			{
				 model.cart.drain();
				 if ( model.cart.paymentMethod == CartModel.NOTES ) model.cart.paymentMethod = CartModel.CARDS;
			}
		}

		protected function handleReviewOrPrint ( evt : MouseEvent ) : void
		{
			timeoutTimer.reset();
			timeoutTimer.stop();

			trace('ConfirmScreen::handleReviewOrPrint()');

			if ( !checkCartTotals() ) return;

			if ( state == REVIEW )
			{
				promptForPaymentMethod();
			}
			else
			{
				startPrintingProcess();
			}

			checkoutBtnEnabled = false;
		}

		protected function checkCartTotals ( ) : Boolean
		{
			var view : View = View.getInstance();

			var minimum : Number = model.host.minCartValue;
			var total : Number = model.cart.commissionedTotal;

			if ( total < minimum && !model.cart.isCharityPurchase )
			{
				var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( "108", { message : { cart_limit : StringUtil.currencyLabelFunction ( minimum ) } } ) );
				view.addChild ( alert );

				checkoutBtnEnabled = false;

				return false;
			}else
			{
				return true;
			}

		}

		protected function promptForPaymentMethod () : void
		{
			model.cart.clearTransactionFees();
			txnFee.visible = false;

			if ( model.cart.paymentMethod == CartModel.COINS )
			{
				handlePaymentMethodSelection( null );
			}
			else
			{
				var overlay : PaymentOptionOverlay = new PaymentOptionOverlay();
				overlay.addEventListener ( Event.CLOSE, handlePaymentMethodSelection, false, 0, true );
				View.getInstance().modalOverlay.currentContent = overlay;
			}
		}

		protected function handlePaymentMethodSelection ( evt : Event ) : void
		{
			var view : View = View.getInstance();
			var controller : Controller = Controller.getInstance();

			if (evt == null) // coins
				model.cart.paymentMethod = CartModel.COINS;
			else
			{
				switch ( ( evt.target as PaymentOptionOverlay ).dismissReason )
				{
					case PaymentOptionOverlay.CARDS:
					{
						model.cart.paymentMethod = CartModel.CARDS;
						// Prompt for card type
						var cardOverlay : CardPaymentSurchargeOverlay = new CardPaymentSurchargeOverlay();
						cardOverlay.addEventListener ( Event.CLOSE, handleCardPaymentSurchargeSelection, false, 0, true );
						View.getInstance().modalOverlay.currentContent = cardOverlay;
						return;
					}

					case PaymentOptionOverlay.NOTES:
					{
						model.cart.paymentMethod = CartModel.NOTES;
						// Prompt for note confirmation
						var noteOverlay : NotePaymentNoticeOverlay = new NotePaymentNoticeOverlay();
						noteOverlay.addEventListener ( Event.CLOSE, handleNotePaymentNoticeSelection, false, 0, true );
						View.getInstance().modalOverlay.currentContent = noteOverlay;
						return;
					}
				}
			}

			reviewCart();
		}

		protected function handleNotePaymentNoticeSelection ( evt : Event ) : void
		{
			switch ( (evt.target as NotePaymentNoticeOverlay).dismissReason )
			{
				case NotePaymentNoticeOverlay.CARDS:
				{
					model.cart.paymentMethod = CartModel.CARDS;
					// Prompt for card type
					var cardOverlay : CardPaymentSurchargeOverlay = new CardPaymentSurchargeOverlay();
					cardOverlay.addEventListener ( Event.CLOSE, handleCardPaymentSurchargeSelection, false, 0, true );
					View.getInstance().modalOverlay.currentContent = cardOverlay;
					return;
				}
				case NotePaymentNoticeOverlay.NOTES:
				{
					model.cart.paymentMethod = CartModel.NOTES;
					break;
				}
			}

			reviewCart();
		}

		protected function handleCardPaymentSurchargeSelection ( evt : Event ) : void
		{
			reviewCart();
		}

		protected function reviewCart( ) : void
		{
			TimeoutManager.lock();
			_estimatedPrice = _displayPrice;
			reviewAlert = Alert.createMessageAlert ( "Reviewing...");
			View.getInstance().addChild ( reviewAlert );
			var token : ReviewCartToken = controller.review ( model.cart.getPrinterQueue() );
			token.addEventListener ( TokenEvent.COMPLETE, onReviewCartComplete, false, 0, true );
			token.addEventListener ( TokenEvent.ERROR, onReviewCartError, false, 0, true );
		}

		protected function onReviewCartComplete ( evt : TokenEvent ) : void
		{
			var hasErrors : Boolean = model.cart.applyReviewedChanges ( evt.data );
			if ( reviewAlert ) reviewAlert.dismiss();

			if (state == CONFIRM)
			{
				updateTotal();
				/*addCardsBtn.visible = false;*/
				emptyCartBtn.visible = false;
				if ( !hasErrors )
				{
					timeoutTimer.reset();
					timeoutTimer.start();
					checkoutBtnEnabled = true;
				}
				else
					checkoutBtnEnabled = false;
			}
			else
			{
				TimeoutManager.unlock();

				/*addCardsBtn.visible = true;*/
				emptyCartBtn.visible = true;

				if ( !hasErrors )
				{
					state = PAY;
					checkoutBtnEnabled = true;
					trace("Estimated Price = " + _estimatedPrice + ", Final Price = " + model.cart.commissionedTotal);
					if (model.cart.transactionFees.length > 0)
					{
						var fee : Object = model.cart.transactionFees[0];
						txnFee.nameField.text = fee.description;
						/*txnFee.totalField.text = StringUtil.currencyLabelFunction ( fee.cost );*/
						txnFee.visible = true;
					}
					if (model.cart.commissionedTotal == _estimatedPrice) // no changes so go straight to payment
						handleReviewOrPrint(null);
				}else
				{
					checkoutBtnEnabled = false;
					generateErroredItemsAlert( );
				}
			}
		}

		protected function onReviewCartError ( evt : TokenEvent ) : void
		{
			TimeoutManager.unlock();
			checkoutBtnEnabled = true;

			if ( reviewAlert ) reviewAlert.dismiss();
			var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( evt.data ) );

			var view : View = View.getInstance();
				view.addChild ( alert );
		}

		protected function startPrintingProcess ( ) : void
		{
			var view : View = View.getInstance();
			TimeoutManager.lock();

			// Woolworths Everyday Rewards
			if ((model.host.uiOptions & HostModel.UI_OPTIONS_WOOLWORTHS_CAPTURE_EDR != 0) && !_loyaltyCardCaptured)
			{
				var scanOverlay : WoolworthsEDROverlay = new WoolworthsEDROverlay();
				scanOverlay.addEventListener ( Event.CLOSE, onWoolworthsEDROverlayClose, false, 0, true );
				view.modalOverlay.currentContent = scanOverlay;
				scanOverlay.captureBarcode();
				_overlayTimer.reset();
				_overlayTimer.start();
				return;
			};

			var minimum : Number = model.host.minCartValue;
			var total : Number = model.cart.commissionedTotal;
			var service : CardPrintingService;

			if ( total < minimum && !model.cart.isCharityPurchase)
			{
				var alert : Alert = Alert.show ( ErrorManager.getErrorByCode ( "108", { message : { cart_limit : StringUtil.currencyLabelFunction ( minimum ) } } ) );
				view.addChild ( alert );
			}else
			{
				if ( model.cart.paymentMethod == CartModel.COINS )
				{
					checkoutAlert = Alert.createMessageAlert ( "Processing...");
					View.getInstance().addChild ( checkoutAlert );

					service = controller.startCoinPayment();
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL, onPaymentSuccess, false, 0, true );
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_ERROR, onPaymentError, false, 0, true );
				}
				else if ( model.cart.paymentMethod == CartModel.NOTES &&
			      	 	  state == CONFIRM)
				{
					checkoutAlert = Alert.createMessageAlert ( "Processing...");
					View.getInstance().addChild ( checkoutAlert );

					service = controller.startNotePayment();
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_SUCCESSFUL, onPaymentSuccess, false, 0, true );
					service.addEventListener ( CardPrinterServiceEvent.PAYMENT_ERROR, onPaymentError, false, 0, true );
				}
				else if ( model.cart.paymentMethod == CartModel.CARDS ||
				          model.cart.paymentMethod == CartModel.NOTES )
				{
					verifyPresuppliedInfo();
				}

				checkoutBtnEnabled = false;
			}
		}

		protected function onOverlayTimeout( evt : TimerEvent ) : void
		{
			View.getInstance().modalOverlay.hide();
			onWoolworthsEDROverlayClose(null);
		}

		protected function onWoolworthsEDROverlayClose ( evt : Event ) : void
		{
			_overlayTimer.reset();
			_loyaltyCardCaptured = true;
			startPrintingProcess();
		}

		protected function verifyPresuppliedInfo ( ) : void
		{
			verifyAlert = Alert.createMessageAlert ( "Connecting...");
			View.getInstance().addChild ( verifyAlert );

			var mobile : String = model.host.customerMobile;
			var pin : String = model.host.customerPin;

			var verifyPinToken : VerifyPinToken = new VerifyPinToken();
				verifyPinToken.addEventListener ( TokenEvent.COMPLETE, onVerifiedPresuppliedPinSuccess, false, 0, true );
				verifyPinToken.addEventListener ( TokenEvent.ERROR, onVerifiedPresuppliedPinError, false, 0, true );
				verifyPinToken.start({ mobile : mobile, pin : pin });
		}

		protected function onVerifiedPresuppliedPinSuccess ( evt : TokenEvent ) : void
		{
			if ( verifyAlert ) verifyAlert.dismiss();
			model.user.loginData = evt.data;

			if ( model.cart.paymentMethod == CartModel.NOTES )
			{
				View.getInstance().modalOverlay.currentContent = new NoteAcceptorOverlay();
			}
			else
				controller.startPinPadTransaction();
		}

		protected function onVerifiedPresuppliedPinError ( evt : TokenEvent ) : void
		{
			if ( verifyAlert ) verifyAlert.dismiss();
			View.getInstance().addChild ( Alert.show ( ErrorManager.getInstance().getErrorByCode ( evt.data )));//"150" ) ) );
			checkoutBtnEnabled = true;
		}

		protected function onPaymentSuccess ( evt : CardPrinterServiceEvent ) : void
		{
			trace("ConfirmScreen.onPaymentSuccess")
			if ( checkoutAlert ) checkoutAlert.dismiss();
		}

		protected function onPaymentError ( evt : CardPrinterServiceEvent ) : void
		{
			trace("ConfirmScreen.onPaymentError")
			if ( checkoutAlert ) checkoutAlert.dismiss();
		}

		override protected function onHide() : void
		{
			trace('ConfirmScreen::onHide()')
			super.onHide();

			if ( reviewAlert ) reviewAlert.dismiss();
			checkoutBtnEnabled = true;
		}

		protected function showMobileCaptureOverlay ( ) : void
		{
			var login : LoginOverlay = new LoginOverlay(LoginOverlay.CREATE);

			if (model.cart.paymentMethod == CartModel.NOTES)
				login.addEventListener ( LoginEvent.LOGIN, continueToNoteOverlay, false, 0, true );
			else
				login.addEventListener ( LoginEvent.LOGIN, continueToPinPadOverlay, false, 0, true );
			login.addEventListener ( Event.CANCEL, onCancelLogin, false, 0, true );

			View.getInstance().modalOverlay.currentContent = login;
		}

		protected function continueToNoteOverlay ( evt : LoginEvent ) : void
		{
			model.user.loginData = evt.data;
			View.getInstance().modalOverlay.currentContent = new NoteAcceptorOverlay();
		}

		protected function continueToPinPadOverlay ( evt : LoginEvent ) : void
		{
			model.user.loginData = evt.data;
			controller.startPinPadTransaction();
		}

		protected function onCancelLogin ( evt : Event ) : void
		{
			state = REVIEW;
			checkoutBtnEnabled = true;
		}

		protected function onCommissionApplied ( evt : CartEvent ) : void
		{
			cardList.refreshData();
			cardList.redraw();
		}

		protected function handleTimeout ( evt : TimerEvent ) : void
		{
			timeoutTimer.reset();
			timeoutTimer.stop();
			startPrintingProcess();
		}


		protected function showCommissionPopup ( item : Object, relativeTo : MovieClip ) : void
		{
			var commObject : Object = model.partners.getCommissionAndFees ( item.card.partnerID, Model.getInstance().cart.paymentMethod );
			var fees : Number = 0;
			var commission : Number = 0;
			var processingFee : Number = 0;

			relativeTo.hasPopup = true;

			if ( state == REVIEW  )
			{
				var commPrice : Number = model.partners.getCommissionedPrice ( item.card.partnerID, Model.getInstance().cart.paymentMethod, { price : item.perCard } );

				fees = item.amount * commObject.fees;
				processingFee = ( item.amount * commPrice ) - ( item.amount * item.perCard );
				commission = commObject.commission;;
			}else
			{
				for ( var i : String in item ) trace ( i + " : " + item[i] );
				processingFee = ( item.amount * item.adjustedValue ) - ( item.amount * item.adjustedPerCard );
				fees = item.amount * item.fee;
				commission = item.commission;
			}

			var pt : Rectangle = relativeTo.getBounds ( this );
				pt.y += relativeTo.height / 2;
				pt.x -= 5;

			var commissionPopup : MovieClip = new CommissionPopup();
				commissionPopup.feesField.text = fees == 0 ? "Free" : StringUtil.currencyLabelFunction ( fees );
				commissionPopup.commissionField.text = commission == 0 ? "Free" : commission.toString() + '%';
				/*commissionPopup.totalField.text = processingFee == 0 ? "Free" : StringUtil.currencyLabelFunction ( processingFee );*/
				commissionPopup.mouseChildren = false;
				commissionPopup.originator = relativeTo;

				commissionPopup.y = pt.y;
				commissionPopup.x = pt.x - 30;
				commissionPopup.alpha = 0;
				commissionPopup.buttonMode = true;
				commissionPopup.addEventListener ( MouseEvent.CLICK, closeCommissionPopup, false, 0, true );

			addChild ( commissionPopup );

			DisplayUtil.top ( commissionPopup );
			TweenMax.to ( commissionPopup, 0.4, { x : pt.x, y : pt.y, autoAlpha : 1, ease : Quint.easeInOut } );
			TweenMax.to ( commissionPopup, 0.4, { x : pt.x - 50, y : pt.y, autoAlpha : 0, ease : Quint.easeInOut, delay : 2, onComplete : cleanupCommissionPopup, onCompleteParams : [ commissionPopup ] } );
		}

		protected function closeCommissionPopup ( evt : MouseEvent ) : void
		{
			var clicked : MovieClip = evt.currentTarget as MovieClip;
			TweenMax.killDelayedCallsTo ( clicked );
			TweenMax.to ( clicked, 0.4, { x : "-50", autoAlpha : 0, ease : Quint.easeInOut, onComplete : cleanupCommissionPopup, onCompleteParams : [ clicked ]} );
		}

		protected function cleanupCommissionPopup ( target : MovieClip ) : void
		{
			target.originator.hasPopup = false;
			DisplayUtil.remove ( target);
		}

		protected function generateErroredItemsAlert ( ) : void
		{
			var errorItems : Array = [];

			for ( var i : int = 0; i < model.cart.cartItems.length; i++ )
			{
				if ( model.cart.cartItems[i].hasError ) errorItems.push ( model.cart.cartItems[i] );
			}

			var alert : Alert = new Alert();

			var maxNumItems : int = errorItems.length > 3 ? 3 : errorItems.length;

			var list : List = new List ( MiniCartItem );
			list.setSize ( 331, maxNumItems * 68 );
			list.list.verticalSpacing = 3;
			list.dataProvider = errorItems;

			var title : TitleText = new TitleText();
			title.textFormat = { size : 24, multiline : true, color : Environment.overlayTextColor }
			title.width = 331;
			title.height = 40;
			title.title = "The following items\ncannot be purchased."

			list.y = title.y + title.height + 50;

			var okBtn : Button = new Button();
			okBtn.data = { alert : alert };
			okBtn.label = "OK"
			okBtn.selected = false;
			okBtn.selectable = false;
			okBtn.redraw();
			okBtn.applySelection();
			okBtn.move ( list.width / 2 - okBtn.width / 2 - 5, list.y + list.height + 30 );
			okBtn.addEventListener ( MouseEvent.MOUSE_DOWN, dismissReviewErrorAlert, false, 0, true );

			var mc : Component = new Component();
			mc.addChild ( title );
			mc.addChild ( list );
			mc.addChild ( okBtn );
			mc.setSize ( 331, okBtn.y - 10 );

			alert.data = { list : list, delay : 0.2 };
			alert.addContent ( mc );

			var view : View = View.getInstance();
			view.addChild ( alert );


		}

		protected function dismissReviewErrorAlert ( evt : MouseEvent ) : void
		{
			var button : Button = evt.currentTarget as Button;
			var alert : Alert = button.data.alert;
			var list : List = alert.data.list;

			TweenMax.delayedCall ( 1, list.dispose );
			alert.dismiss();
		}

		protected function onItemUpdated ( evt : CartEvent ) : void
		{
			cardList.refreshData();
			checkoutBtnEnabled = true;
			updateTotal();
		}

		protected function onItemAddedToCart ( evt : CartEvent ) : void
		{
			cardList.addItem( evt.data );
			refreshListPosition();
			updateTotal();
		}

		protected function onItemRemovedFromCart ( evt : CartEvent ) : void
		{
			var item : CardListItem = cardList.removeItem( evt.data ) as CardListItem;

			cardList.list.addRogueChild ( item );
			item.animateOut();

			refreshListPosition();
			updateTotal();

			checkForErrorItems();
		}

		protected function onCartDrained ( evt : CartEvent ) : void
		{
			cardList.removeAll();
			refreshListPosition();
			updateTotal();

			if (state != CONFIRM)
				if ( View.getInstance().currentScreenKey == View.CONFIRM_SCREEN ) returnToChooseScreen();
		}

		protected function updateTotal ( ) : void
		{

			if ( state == REVIEW )
			{
				this.totalPrice = model.cart.commissionedEstimateTotal; //model.cart.total;
				_estimatedPrice = this.totalPrice;
			}else
			{
				this.totalPrice = model.cart.commissionedTotal;
			}

			TweenMax.to ( this, 0.2, { displayPrice : totalPrice, ease : Linear.easeNone, onComplete : finalizePriceDisplay });
		}

		protected function finalizePriceDisplay ( ) : void
		{
			displayPrice = totalPrice;
		}

		public function set displayPrice ( d : Number ) : void
		{
			_displayPrice = d;
			var suffix : String = state == REVIEW ? "*" : "";
			/*totalField.text = StringUtil.currencyLabelFunction ( d ) + suffix;*/
		}

		public function get displayPrice ( ) : Number
		{
			return _displayPrice;
		}

		protected function refreshListPosition ( evt : ListEvent = null ) : void
		{
			cardList.list.applyConstrain();
		}

		override public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			super.show ( delay, notify );
			_confirmed = false;
			_loyaltyCardCaptured = false;
			if ( model.cart.paymentMethod == CartModel.COINS )
				state = CONFIRM;
			else
				state = REVIEW;
			updateTotal();
		}

		protected function checkForErrorItems ( ) : void
		{
			var anyErrors : Boolean = false;

			for ( var i : int = 0; i < cardList.listItems.length; i++ )
			{
				if ( cardList.listItems[i].hasError ) anyErrors = true;
			}

			if ( !anyErrors )
			{
				checkoutBtnEnabled = true;
			}
		}

		protected function handleListItemInteraction ( evt : ListEvent ) : void
		{
			switch ( evt.action )
			{
				case CardListItem.HELP_INTERACTION :
				{
					if ( evt.originator.hasPopup ) return;
					showCommissionPopup ( evt.listItem.data, evt.originator );
					break;
				}

				case CardListItem.EDIT_INTERACTION :
				{
					var overlay : AddCardsOverlay = new AddCardsOverlay();
						overlay.state = AddCardsOverlay.UPDATE;
						overlay.data = evt.listItem.data;

					View.getInstance().modalOverlay.currentContent = overlay;

					break;
				}

				case CardListItem.DELETE_INTERACTION :
				{
					model.cart.removeItem ( evt.listItem.data );
					if (_state == CONFIRM)
					{
						if (model.cart.totalCardsInCart <= 0)
							model.cart.adjustCartForUnderPayment(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0], model.user.applicableBalance);
						else
							model.cart.adjustCartForOverPayment(model.cards.hostPrimaryProducts([CardModel.PRIMARY_CARD_1])[0], model.user.applicableBalance)
						var token : ReviewCartToken = controller.review ( model.cart.getPrinterQueue(), true );
						token.addEventListener ( TokenEvent.COMPLETE, onReviewCartComplete, false, 0, true );
						token.addEventListener ( TokenEvent.ERROR, onReviewCartError, false, 0, true );
					}
					break;
				}
			}
		}

		protected function set checkoutBtnEnabled( b : Boolean ) : void
		{
			checkoutBtn.enabled = b;

			if ( checkoutBtn.enabled )
			{
				if ( !checkoutBtnTween )
					checkoutBtnTween = DisplayUtil.startPulse( checkoutBtn );
			}
			else
			{
				DisplayUtil.stopPulse( checkoutBtnTween );
				checkoutBtnTween = null;
			}
		}

		protected function returnToChooseScreen ( evt : MouseEvent = null ) : void
		{
			model.cart.clearTransactionFees();
			txnFee.visible = false;
			if ( model.cart.paymentMethod == CartModel.NOTES ) model.cart.paymentMethod = CartModel.CARDS;
			View.getInstance().currentScreenKey = View.CHOOSE_SCREEN;
		}

	}
}
