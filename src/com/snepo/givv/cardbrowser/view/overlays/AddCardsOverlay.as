package com.snepo.givv.cardbrowser.view.overlays
{
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

	public class AddCardsOverlay extends Component implements IOverlay
	{

		public static const PREDEFINED_VALUES : String = "AddCardsOverlay.PREDEFINED_VALUES";
		public static const KEYPAD_VALUES : String = "AddCardsOverlay.KEYPAD_VALUES";

		public static const CREATE : String = "AddCardsOverlay.CREATE";
		public static const UPDATE : String = "AddCardsOverlay.UPDATE";
		public static const INSTANT : String = "AddCardsOverlay.INSTANT";

		public var keypad : Keypad;
		public var predefined : PredefinedValueBox;
		public var cardNameTitle : TitleText;

		protected var _state : String = CREATE;
		protected var _entryMethod : String = PREDEFINED_VALUES;

		protected var _editedButNotCommitted : Boolean = false;
		protected var hasAlert : Boolean = false;
		protected var testAlert : MovieClip;
		protected var descriptionScroller : Container;
		public var closeReason : String = "";

		protected var maxDescriptionHeight : Number;
		public var scanData : Object = null;

		public function AddCardsOverlay ( )
		{
			super();

			_width = 250;
			_height = 715;
		}

		public function onRequestClose ( ) : void
		{
			if ( hasAlert ) return;
			hasAlert = true;

			var overlay : ModalOverlay = View.getInstance().modalOverlay;

			testAlert = new TestAlert();
			testAlert.y = addBtn.y + 80;
			testAlert.x = overlay.currentContent.x - 30;
			testAlert.alpha = 0;

			overlay.addChild ( testAlert );

			TweenMax.to ( testAlert, 0.5, { alpha : 1, x : overlay.currentContent.x - 5, ease : Back.easeOut } );
			TweenMax.to ( testAlert, 0.5, { alpha : 0, x : overlay.currentContent.x - 30, ease : Back.easeIn, delay : 1.2, onComplete : destroyAlert, onCompleteParams : [ testAlert ] } );

		}

		protected function destroyAlert ( m : MovieClip ) : void
		{
			DisplayUtil.remove ( m );
			testAlert = null;
			hasAlert = false;
		}

		public function get canClose ( ) : Boolean
		{
			if ( state == CREATE || state == INSTANT ) return true;

			return !_editedButNotCommitted;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			model.cards.addEventListener ( CardEvent.SELECTED_CARD_CHANGED, onSelectedCardChanged );

			var maxCards : int = model.host.maxCartCards;

			addChild ( descriptionScroller = new Container() );
			descriptionScroller.padding = 0;
			descriptionScroller.horizontalScrollEnabled = false;
			descriptionScroller.verticalScrollEnabled = true;
			descriptionScroller.layoutStrategy = null;
			descriptionScroller.addChild ( descriptionField );
			descriptionScroller.move ( descriptionField.x, descriptionField.y );
			descriptionScroller.setSize ( descriptionField.width, descriptionField.height );
			descriptionField.x = descriptionField.y = 0;

			maxDescriptionHeight = descriptionScroller.height;

			addChild ( keypad = new Keypad() );
			keypad.minValue = 10;
			keypad.maxValue = Math.min( model.host.maxCardValue, model.host.maxCartValue );
			keypad.move ( 5, 211 );
			keypad.setSize ( 240, 282 );
			keypad.addEventListener ( Event.CHANGE, updateAddCartBtn );
			keypad.visible = false;
			keypad.alpha = 0;
			keypad.maxChars = (keypad.maxValue < 999 ? 3 : 4);

			stepper.addEventListener ( Event.CHANGE, updateEditState );
			stepper.maximum = maxCards;

			addChild ( predefined = new PredefinedValueBox() );
			predefined.move ( 5, 211 );
			predefined.setSize ( 240, 282 );
			predefined.addEventListener ( Event.CHANGE, updateByPredefinedValue );

			addChild ( cardNameTitle = new TitleText() );
			cardNameTitle.setSize ( 272, 35 );
			cardNameTitle.move ( 1, 0 );
			cardNameTitle.textFormat = { size : 26, align : "left", color : 0xFFFFFF };
			cardNameTitle.textProperties = { multiline : true, wordWrap : true };
			cardNameTitle.center = false;

			addBtn.label = "ADD TO CART"
			addBtn.offFillColor = Environment.forwardButtonColor;
			addBtn.onLabelColor = 0xFFFFFF;
			addBtn.offLabelColor = 0xFFFFFF;
			addBtn.selected = false;
			addBtn.selectable = false;
			addBtn.redraw();
			addBtn.applySelection();
			addBtn.addEventListener ( MouseEvent.MOUSE_DOWN, addItemToCart );
			DisplayUtil.startPulse( addBtn );

			cancelBtn.label = "CANCEL"
			cancelBtn.offFillColor = 0xBD0000; // red
			cancelBtn.onLabelColor = 0xFFFFFF;
			cancelBtn.offLabelColor = 0xFFFFFF;
			cancelBtn.selected = false;
			cancelBtn.selectable = false;
			cancelBtn.redraw();
			cancelBtn.applySelection();
			cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay );

			data = model.cards.selectedCard;

		}

		public function set entryMethod ( s : String ) : void
		{
			_entryMethod = s;
			applyEntryMethod();
		}

		public function get entryMethod ( ) : String
		{
			return _entryMethod;
		}

		protected function applyEntryMethod ( ) : void
		{
			trace('AddCardsOverlay::applyEntryMethod() - ' + entryMethod)
			switch ( entryMethod )
			{
				case PREDEFINED_VALUES :
				{
					predefined.x = -predefined.width;
					predefined.alpha = 0;
					TweenMax.to ( predefined, 0.7, { x : 5, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.to ( keypad, 0.7, { x : this.width + 5, autoAlpha : 0, ease : Quint.easeInOut } );
					break;
				}

				case KEYPAD_VALUES :
				{
					keypad.x = -keypad.width;
					keypad.alpha = 0;
					TweenMax.to ( keypad, 0.7, { x : 5, autoAlpha : 1, ease : Quint.easeInOut } );
					TweenMax.to ( predefined, 0.7, { x : this.width + 5, autoAlpha : 0, ease : Quint.easeInOut } );
					break;
				}

			}

			updateAddCartBtn ( null );
		}

		public function set state ( s : String ) : void
		{
			_state = s;
			applyState();
		}

		public function get state ( ) : String
		{
			return _state;
		}

		protected function applyState ( ) : void
		{

			switch ( state )
			{
				case UPDATE :
				{
					_editedButNotCommitted = false;

					cancelBtn.label = "DELETE";
					cancelBtn.redraw();
					cancelBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay );
					cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, deleteItem );
					cancelBtn.offFillColor = 0xBD0000; // red
					cancelBtn.applySelection();

					addBtn.label = "UPDATE";
					addBtn.redraw();
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, addItemToCart );
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, purchaseScannedItem );
					addBtn.addEventListener ( MouseEvent.MOUSE_DOWN, updateItemInCart );

					if (data.hasOwnProperty('card') && data.card.hasOwnProperty('processas') && data.card.processas == CardModel.SCANNABLE)
					{
						numOfCards.visible = false;
						stepper.visible = false;
					}
					break;
				}

				case CREATE :
				{
					cancelBtn.label = "CANCEL";
					cancelBtn.redraw();
					cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay );
					cancelBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, deleteItem );
					cancelBtn.offFillColor = 0xBD0000; // red
					cancelBtn.applySelection();

					addBtn.label = "ADD TO CART";
					addBtn.redraw();
					addBtn.addEventListener ( MouseEvent.MOUSE_DOWN, addItemToCart );
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, updateItemInCart );
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, purchaseScannedItem );

					break;
				}

				case INSTANT :
				{
					cancelBtn.label = "CANCEL";
					cancelBtn.redraw();
					cancelBtn.addEventListener ( MouseEvent.MOUSE_DOWN, closeOverlay );
					cancelBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, deleteItem );
					cancelBtn.offFillColor = 0xBD0000; // red
					cancelBtn.applySelection();

					addBtn.label = "ADD TO CART";
					addBtn.redraw();
					addBtn.addEventListener ( MouseEvent.MOUSE_DOWN, purchaseScannedItem );
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, updateItemInCart );
					addBtn.removeEventListener ( MouseEvent.MOUSE_DOWN, addItemToCart );
					addBtn.applySelection();
					break;

				}
			}
		}

		protected function onSelectedCardChanged ( evt : CardEvent ) : void
		{
			trace("AddCardsOverlay - onSelectedCardChanged()")
			if ( state == CREATE )
			{
				if ( model.cards.selectedCard.processas != CardModel.SCANNABLE )
				{
					scanData = null;
					data = model.cards.selectedCard;
				}else
				{
					var scanOverlay : BarcodeCardOverlay = new BarcodeCardOverlay();
						scanOverlay.data = model.cards.selectedCard;

					View.getInstance().modalOverlay.currentContent = scanOverlay;
					scanOverlay.captureSpecificCard();
				}
			}else
			{
				closeOverlay();
			}
		}

		protected function purchaseScannedItem ( evt : MouseEvent ) : void
		{
			model.cards.currentScanData = scanData;
			View.getInstance().modalOverlay.currentContent = new CheckoutStep1Overlay();
		}

		override public function dispose ( ) : void
		{
			super.dispose();

			model.cards.removeEventListener ( CardEvent.SELECTED_CARD_CHANGED, onSelectedCardChanged );

		}

		override protected function render ( ) : void
		{
			if ( state == CREATE || state == INSTANT )
			{
				trace('AddCardsOverlay::render() - Predefined values = ' + model.cards.selectedCard.allowUserValue.toString())
				if ( !model.cards.selectedCard.allowUserValue ) entryMethod = PREDEFINED_VALUES;

				var predefinedValues : Array = getPredefinedValuesForCard ( model.cards.selectedCard );

				cardNameTitle.title = model.cards.selectedCard.name;
				renderDescription(model.cards.selectedCard.description);
				predefined.values = predefinedValues;
				predefined.redraw();
				if (model.cards.selectedCard.minValue >= 0)
					keypad.minValue = model.cards.selectedCard.minValue;
				else
					keypad.minValue = 10;
				if (model.cards.selectedCard.maxValue >= 0)
					keypad.maxValue = model.cards.selectedCard.maxValue;
				else
					keypad.maxValue = Math.min( model.host.maxCardValue, model.host.maxCartValue );
				keypad.invalidateValue();
			}else
			{
				prepopulate();
				state = UPDATE; // change UI for scannable cards
			}
		}

		protected function deleteItem ( evt : MouseEvent ) : void
		{
			_editedButNotCommitted = false;
			model.cart.removeItem ( this.data );

			if ( testAlert )
			{
				var overlay : ModalOverlay = View.getInstance().modalOverlay;

				TweenMax.killTweensOf ( testAlert );
				TweenMax.to ( testAlert, 0.5, { alpha : 0, x : overlay.currentContent.x - 30, ease : Back.easeIn, onComplete : destroyAlert, onCompleteParams : [ testAlert ] } );
			}

			closeOverlay();
		}

		protected function updateByPredefinedValue ( evt : Event ) : void
		{
			trace("AddCordsOverlay::updateByPredefinedValue() - " + predefined.selectedValue.value.toString())
			if ( predefined.selectedValue.value == "+" )
			{
				entryMethod = KEYPAD_VALUES;
			}
//			else
//				entryMethod = PREDEFINED_VALUES;

			updateAddCartBtn ( null );

		}

		protected function updateItemInCart ( evt : MouseEvent ) : void
		{
			_editedButNotCommitted = false;

			var diff : Object = { perCard : getEntryMethodValue(), entryMethod : this.entryMethod, amount : stepper.value }

			model.cart.applyUpdate ( data, diff );

			if ( testAlert )
			{
				var overlay : ModalOverlay = View.getInstance().modalOverlay;

				TweenMax.killTweensOf ( testAlert );
				TweenMax.to ( testAlert, 0.5, { alpha : 0, x : overlay.currentContent.x - 30, ease : Back.easeIn, onComplete : destroyAlert, onCompleteParams : [ testAlert ] } );
			}

			closeOverlay();
		}

		protected function prepopulate ( ) : void
		{
			cardNameTitle.title = data.card.name;
			renderDescription(data.card.description);
			stepper.value = data.amount;

			trace('AddCardsOverlay::prepopulate()')
			keypad.firstTouch = true;

			if ( data.isMax )
			{
				this.entryMethod = PREDEFINED_VALUES;
			}else
			{
				trace('AddCardsOverlay::prepopulate() - entryMethod = ' + data.entryMethod)
				this.entryMethod = data.entryMethod;
			}

			switch ( entryMethod )
			{
				case KEYPAD_VALUES :
				{
					trace ( "AddCardsOverlay::prepopulate() - variable - " + data.entryMethod );
					keypad.value = data.perCard.toFixed(2).replace(".00", "") + "";
					break;
				}

				case PREDEFINED_VALUES :
				{
					trace( "AddCardsOverlay::prepopulate() - predefined - " + data.entryMethod )
					predefined.values = getPredefinedValuesForCard ( data.card );
					predefined.selectButtonByValue ( "$" + data.perCard );
					predefined.redraw();
					break;
				}
			}

			trace('AddCardsOverlay::prepopulate() - end')
			_editedButNotCommitted = false;
		}

		protected function getPredefinedValuesForCard ( card : Object ) : Array
		{
			var denoms : Array = card.denominations.concat();

			for ( i = 0; i < denoms.length; i++ )
			{
				denoms[i].enabled = true;
			}

			var model : Model = Model.getInstance();
			var balance : Number = model.user.applicableBalance;

			var i : int;
			var denom : Object;
			var lastDenom : Object;
			var commissionPrice : Number;

			if ( model.cart.paymentMethod == CartModel.COINS && model.user.hasUser )
			{
				for ( i = 0; i < denoms.length; i++ )
				{
					denom = denoms[i];

					commissionPrice = model.partners.getCommissionedPrice ( card.partnerID, model.cart.paymentMethod, denom );

					if ( ( model.cart.commissionedEstimateTotal + commissionPrice ) > balance )
					{
						denom.enabled = false;
						if ( denom.isDefault && lastDenom != null ) lastDenom.isDefault = true;
					}else
					{
						denom.enabled = true;
					}

					if ( denom.enabled ) lastDenom = denom;
				}
			}

			if ( model.cart.paymentMethod == CartModel.COINS && card.allowUserValue && model.user.hasUser )
			{
				// Max sure the max is the default

				for ( i = 0; i < denoms.length; i++ )
				{
					denom = denoms[i];
					denom.isDefault = false;
				}

				var id : int = -1;
				var isDefault : Boolean = true;
				var value : Number = model.partners.getMaxValueForBalanceWithCommission ( card.partnerID, model.cart.paymentMethod, balance );
				var label : String = StringUtil.currencyLabelFunction ( value );
				var price : Number = value;

				if ( value >= model.host.minCartValue && value <= 1000 || card.api == "charity")
				{
					if ( value < 1 ) label = value.toFixed(2).replace(".00", "") + "c";
					denoms.splice ( 0, 0, { id : id, isDefault : isDefault, label : label, value : value, price : price, isMax : true } );
				}
			}

			return denoms;
		}

		protected function renderDescription ( desc : String ) : void
		{
			descriptionField.text = desc;
			var dHeight : Number = descriptionField.textHeight + 5 < maxDescriptionHeight ? descriptionField.textHeight + 5 : maxDescriptionHeight;

			descriptionScroller.verticalScrollEnabled = (descriptionField.textHeight + 5) > maxDescriptionHeight;
			descriptionScroller.content.y = 0;

			TweenMax.to ( descriptionScroller, 0.4, { y : cardNameTitle.y + cardNameTitle.nextHeight + 5, height : dHeight, ease : Quint.easeInOut } );
			TweenMax.to ( descriptionField, 0.4, {  height : descriptionField.textHeight + 5, ease : Quint.easeInOut } );
			TweenMax.to ( addCardsTitle, 0.4, { y : cardNameTitle.y + cardNameTitle.nextHeight + 5 + dHeight + 5, ease : Quint.easeInOut } );

			var predefinedEndY : Number = cardNameTitle.y + cardNameTitle.nextHeight + dHeight + 46;

			TweenMax.to ( predefined, 0.4, { y : predefinedEndY, height : ( stepper.y - 38 ) - predefinedEndY, ease : Quint.easeInOut } );
			TweenMax.to ( keypad, 0.4, { y : predefinedEndY, height : ( stepper.y - 38 ) - predefinedEndY, ease : Quint.easeInOut } );
		}

		protected function updateAddCartBtn ( evt : Event ) : void
		{
			addBtn.enabled = getEntryMethodValue() != 0;

			_editedButNotCommitted = true;
		}

		protected function updateEditState ( evt : Event ) : void
		{
			_editedButNotCommitted = true;
		}

		protected function getEntryMethodValue ( ) : Number
		{
			trace('AddCardsOverlay::getEntryMethodValue()')
			var model : Model = Model.getInstance();

			if ( entryMethod == KEYPAD_VALUES )
			{
				if ( !keypad ) return 0;
				if ( !keypad.isValidValue ) return 0;

				if ( model.cart.paymentMethod == CartModel.COINS )
				{
					var balance : Number = model.user.applicableBalance;
					var value : Number = Number ( keypad.value );
					var commissionPrice : Number = model.partners.getCommissionedPrice ( model.cards.selectedCard.partnerID, model.cart.paymentMethod, { price : value } );

					if ( ( model.cart.commissionedEstimateTotal + commissionPrice ) > balance ) return 0;
				}

				return Number ( keypad.value );
			}else
			{
				if ( !predefined.selectedValue ) return 0;
				if ( predefined.selectedValue.hasOwnProperty ( "enabled" ) && !predefined.selectedValue.enabled ) return 0;
				return Number ( predefined.selectedValue.price );
			}
		}

		protected function addItemToCart ( evt : Event ) : void
		{

			var item : Object = { };
				item.card = model.cards.selectedCard;
				item.amount = stepper.value;
				item.perCard = getEntryMethodValue();
				item.entryMethod = this.entryMethod;
				item.isMax = predefined.selectedValue.isMax;

			if ( scanData != null )
			{
				item.upc = scanData.upc;
				item.scanNumber = scanData.cardNumber;
				model.cards.currentScanData = scanData;
			}

			if ( entryMethod == PREDEFINED_VALUES && predefined.selectedValue.promotion )
			{
				item.promotion = true;
				item.promotionValue = predefined.selectedValue.value;
			}

			model.cart.addItem( item );

			closeOverlay();
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
			stepper.width = 240;
			keypad.width = 240;
			predefined.width = 240;

		}

		protected function closeOverlay ( evt : MouseEvent = null ) : void
		{
			View.getInstance().modalOverlay.hide();

			if ( evt && evt.currentTarget == cancelBtn )
			{
				closeReason = "cancel";
			}else
			{
				closeReason = "added";
			}

			dispatchEvent ( new Event ( Event.CLOSE ) );

		}

	}

}
