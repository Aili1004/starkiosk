package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
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

	public class ChooseScreen extends Screen
	{
		public var coverflow : Coverflow;
		public var filterButtons : FilterButtonBar;
		public var smallCart : SmallCart;
		public var redeemBtn : MovieClip;
		var closeIcon : MovieClip = new CloseIcon();

		protected var instructionText : ChooseInstructionText;
		protected var view : View;

		public function ChooseScreen ( )
		{
			super();

			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addChild(closeIcon);
			closeIcon.closeBtn.addEventListener (MouseEvent.CLICK, closeCurrentPage);

			addChild(redeemBtn = new RedeemForCasinoDollarBtn());
			redeemBtn.redeemCD.addEventListener ( MouseEvent.CLICK, redeemCDPage);

			instructionText = new ChooseInstructionText();
			instructionText.y = 125;
			instructionText.x = (View.APP_WIDTH / 2) - (instructionText.width / 2);
			instructionText.text.text = Environment.chooseScreenInstructionText;
			addChild ( instructionText );

			coverflow = new Coverflow();
			coverflow.primaryCoverflow = true;
			coverflow.setSize ( View.APP_WIDTH, 300 );
			coverflow.y = View.APP_HEIGHT / 2;
			addChild ( coverflow );
			coverflow.addEventListener ( Event.SELECT, selectActiveCard );

 			filterButtons = new FilterButtonBar();
			filterButtons.setSize ( View.APP_WIDTH, 50 );
			filterButtons.addEventListener( Event.CHANGE, filterCoverflow );
			filterButtons.y = 140;
			filterButtons.dataProvider = model.categories.categories;
			addChild ( filterButtons );

			smallCart = new SmallCart();
			smallCart.x = 5;
			smallCart.y = View.APP_HEIGHT - smallCart.height - 5;
			addChild ( smallCart );
		}

		protected function closeCurrentPage (evt : MouseEvent) : void
		{
			View.getInstance().currentScreenKey = View.HOME_SCREEN;
		}

		protected function redeemCDPage ( evt : MouseEvent ) : void
		{
			trace("hello world");
		}


		override public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			super.show ( delay, notify );
		}

		public function reset ( ) : void
		{
			filterButtons.select ( 0 );
			coverflow.selectedIndex = 0;
		}

		protected function selectActiveCard ( evt : Event ) : void
		{
			var view : View = View.getInstance();

			if ( model.cards.selectedCard.processas == CardModel.SCANNABLE )
			{
				var scanOverlay : BarcodeCardOverlay = new BarcodeCardOverlay();
				if ( !(view.modalOverlay.currentContent is BarcodeCardOverlay) )
				{
					view.modalOverlay.currentContent = scanOverlay;
					scanOverlay.data = model.cards.selectedCard;
				}
				scanOverlay.captureSpecificCard();
			}else
			{
				if ( !(view.modalOverlay.currentContent is AddCardsOverlay) )
				{
					view.modalOverlay.currentContent = new AddCardsOverlay();
				}
			}

		}

		public function set selectedCard (card : Object) : void
		{
			// set correct filter button
			trace("Card = " + card.name.toString());
			var category : Object = model.categories.getCategoryByFlag(card.categoryBits);
			if (category != null)
			{
				trace("Selecting Category: " + category.label);
				filterButtons.selectByLabel(category.label);
				coverflow.slideToCard(card);
			}
			else
				model.cards.selectedCard = card;
		}

		public function showCharityCards ( ) : void
		{
			coverflow.dataProvider = model.cards.charityCards;
			filterButtons.select ( -1, true );
			filterButtons.visible = false;
		}

		protected function filterCoverflow ( evt : Event ) : void
		{
			if ( coverflow.dataProvider != model.cards.nonScannableCards ) coverflow.dataProvider = model.cards.nonScannableCards;
			filterButtons.visible = true;
			coverflow.filterType = filterButtons.flag;
		}
	}
}
