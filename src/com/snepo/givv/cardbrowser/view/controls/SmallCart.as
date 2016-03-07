package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;

	public class SmallCart extends Component
	{

		public var list : List;
		public var totalPrice : Number = 0;

		protected var _displayPrice : Number = 0;
		protected var _selectedIndex : int = -1;
		protected var _maxItems : int = 4;

		protected var viewCartBtnTween : TweenMax = null;

		public function SmallCart()
		{
			super();

			_width = 1014;
			_height = 146;
		}

		public function set maxItems ( m : int ) : void
		{
			_maxItems = m;
			layoutList();
		}

		public function get maxItems ( ) : int
		{
			return _maxItems;
		}

		protected function layoutList ( ) : void
		{
			if ( maxItems == 3 )
			{
				TweenMax.to ( list, 0.4, { width : 396, ease : Quint.easeInOut, onComplete : refreshListPosition } )
				TweenMax.to ( rightBtn, 0.4, { x : 512, ease : Quint.easeInOut } )
				TweenMax.to ( placeHolders.b3, 0.4, { alpha : 0, ease : Quint.easeInOut } );

			}else
			{
				TweenMax.to ( list, 0.4, { width : 531, ease : Quint.easeInOut, onComplete : refreshListPosition } )
				TweenMax.to ( rightBtn, 0.4, { x : 643, ease : Quint.easeInOut } )
				TweenMax.to ( placeHolders.b3, 0.4, { alpha : 1, ease : Quint.easeInOut } );
			}
		}

		public function set selectedIndex ( s : int ) : void
		{
			if ( s < 0 ) s = 0;
			if ( s > list.dataProvider.length - 1 ) s = list.dataProvider.length - 1;

			_selectedIndex = s;

			applySelection();

		}

		public function get selectedIndex ( ) : int
		{
			return _selectedIndex;
		}

		public function applySelection ( params : Object = null ) : void
		{
			updateArrows();

			if ( !params ) params = { time : 0.4, ease : Quint.easeOut, delay : 0 }

			var target : SmallCartItem = list.listItems[selectedIndex] as SmallCartItem;

			if ( !target ) return;

			var offset : Number = -target.x;

			if ( list.listItems.length <= maxItems ) offset = 0;

			TweenMax.to ( list.list.content, params.time, { x : offset, delay : params.delay, ease : params.ease } );
		}

		protected function updateArrows ( ) : void
		{

			if (list.dataProvider.length <= maxItems)
			{
				if (leftBtn.visible)
				{
					TweenMax.to ( leftBtn, 0.8, { y : View.APP_HEIGHT, autoAlpha : 0, ease : Back.easeOut, delay : 0.5 } );
					TweenMax.to ( rightBtn, 0.8, { y : View.APP_HEIGHT, autoAlpha : 0, ease : Back.easeOut, delay : 0.5 } );
				}
			}
			else
			{
				if (!leftBtn.visible)
				{
					TweenMax.fromTo ( leftBtn, 0.8, { y : View.APP_HEIGHT }, { y : 45, autoAlpha : 1, ease : Back.easeOut } );
					TweenMax.fromTo ( rightBtn, 0.8, { y : View.APP_HEIGHT }, { y : 45, autoAlpha : 1, ease : Back.easeOut } );
				}

				if ( list.dataProvider.length > 1 && selectedIndex > 0 )
				{
					leftBtn.enabled = true;
				}else
				{
					leftBtn.enabled = false;
				}

				if ( list.dataProvider.length > 1 && selectedIndex < list.dataProvider.length - maxItems )
				{
					rightBtn.enabled = true;
				}else
				{
					rightBtn.enabled = false;
				}
			}
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			model.cart.addEventListener ( CartEvent.ITEM_REMOVED, onItemRemovedFromCart, false, 0, true );
			model.cart.addEventListener ( CartEvent.ITEM_UPDATED, onItemUpdated, false, 0, true );
			model.cart.addEventListener ( CartEvent.ITEM_ADDED, onItemAddedToCart, false, 0, true );
			model.cart.addEventListener ( CartEvent.DRAIN, onCartDrained, false, 0, true );

			addChild ( list = new List( SmallCartItem ) );
			list.addEventListener ( ListEvent.ITEM_INTERACTION, handleListItemInteraction );
			list.addEventListener ( ListEvent.REFRESH, refreshListPosition );
			list.list.layoutStrategy = new HorizontalLayoutStrategy(true, true);
			list.list.addEventListener ( ScrollEvent.THROW, updateIndexByThrow );
			list.list.horizontalSpacing = 9;
			list.list.horizontalScrollEnabled = true;
			list.list.verticalScrollEnabled = false;
			list.list.content.y = 42;
			list.setSize ( 531, 146 );
			list.move ( 100, 0 );
			list.list.content.addChildAt ( placeHolders, 0 );
			placeHolders.x = placeHolders.y = 0;

			leftBtn.label = "";
			leftBtn.icon = new LeftArrowIcon();
			leftBtn.repeating = true;
			leftBtn.repeatRate = 300;
			leftBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );

			rightBtn.label = "";
			rightBtn.icon = new RightArrowIcon();
			rightBtn.repeating = true;
			rightBtn.repeatRate = 300;
			rightBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );
			leftBtn.visible = rightBtn.visible = false;

			viewCartBtn.label = "CHECKOUT";
			viewCartBtn.offFillColor = 0x0080ff; // blue
			viewCartBtn.applySelection();
			viewCartBtn.redraw();
//			viewCartBtn.cornerRadii = { tl : 0, tr : 6, bl : 0, br : 6 };
			viewCartBtn.hideButtonShadow();
			viewCartBtn.addEventListener ( MouseEvent.MOUSE_DOWN, showConfirmScreen );
			viewCartBtn.enabled = false;

			selectedIndex = 0;
		}

		protected function showConfirmScreen ( evt : MouseEvent ) : void
		{

			model.cart.removeAppliedChanges();
			(View.getInstance().getScreen ( View.CONFIRM_SCREEN ) as ConfirmScreen).state = ConfirmScreen.REVIEW;
			View.getInstance().currentScreenKey = View.CONFIRM_SCREEN;
		}

		protected function onItemUpdated ( evt : CartEvent ) : void
		{
			list.refreshData();
			updateTotal();
		}

		protected function onItemAddedToCart ( evt : CartEvent ) : void
		{
			list.addItem( evt.data );
			refreshListPosition();
			updateTotal();
		}

		protected function onItemRemovedFromCart ( evt : CartEvent ) : void
		{
			var item : SmallCartItem = list.removeItem( evt.data ) as SmallCartItem;

			list.list.addRogueChild ( item );
			item.x -= list.list.content.x;
			item.y = list.list.content.y;
			item.animateOut();

			refreshListPosition();
			updateTotal();
		}

		protected function onCartDrained ( evt : CartEvent ) : void
		{
			list.removeAll();
			refreshListPosition();
			updateTotal();

			Environment.FIRST_USER = true;
		}

		protected function updateTotal ( ) : void
		{
			this.totalPrice = model.cart.total;

			TweenMax.to ( this, 0.5, { displayPrice : totalPrice, ease : Linear.easeNone, onComplete : enforceRoundingPrecision })

			viewCartBtn.enabled = model.cart.cartItems.length > 0;
			if ( viewCartBtn.enabled )
			{
				if (!viewCartBtnTween)
					viewCartBtnTween = DisplayUtil.startPulse( viewCartBtn );
			}
			else
			{
				DisplayUtil.stopPulse( viewCartBtnTween );
				viewCartBtnTween = null;
			}

		/*
			if (viewCartBtn.enabled)
				TweenMax.to(viewCartBtn, 0.2, {x:viewCartBtn.x-5, width:viewCartBtn.width+10, y:viewCartBtn.y-5, height:viewCartBtn.height+10, repeat:-1, repeatDelay:0.2, yoyo:true});
			else
			{
				TweenMax.killDelayedCallsTo ( viewCartBtn );
				viewCartBtn.enabled = false;
			} */
		}

		protected function enforceRoundingPrecision ( ) : void
		{
			/*totalField.text = StringUtil.currencyLabelFunction ( totalPrice ) + "*";*/
			/*_displayPrice = totalPrice;*/
		}

		public function set displayPrice ( d : Number ) : void
		{
			/*_displayPrice = d;
			totalField.text = StringUtil.currencyLabelFunction ( Math.round ( d ) ) + "*";*/
		}

		public function get displayPrice ( ) : Number
		{
			return _displayPrice;
		}

		protected function refreshListPosition ( evt : ListEvent = null ) : void
		{
			list.list.applyConstrain();
			updateArrows();
		}

		protected function handleListItemInteraction ( evt : ListEvent = null ) : void
		{

			var view : View = View.getInstance();

			var currentOverlay : AddCardsOverlay = view.modalOverlay.currentContent as AddCardsOverlay;

			switch ( evt.action )
			{
				case SmallCartItem.EDIT_INTERACTION :
				{

					if ( currentOverlay && currentOverlay.data == evt.listItem.data && currentOverlay.state == AddCardsOverlay.UPDATE ) return;

					var overlay : AddCardsOverlay = new AddCardsOverlay();
						overlay.state = AddCardsOverlay.UPDATE;
						overlay.data = evt.listItem.data;

					View.getInstance().modalOverlay.currentContent = overlay;

					break;
				}

				case SmallCartItem.DELETE_INTERACTION :
				{
					Model.getInstance().cart.removeItem ( evt.listItem.data );
					break;
				}
			}

		}

		protected function updateIndexByThrow ( evt : ScrollEvent ) : void
		{
			TweenMax.delayedCall ( 0.7, snapToClosest );
		}

		protected function snapToClosest ( ) : void
		{
			var closest : SmallCartItem;
			var minDistance : Number = Number.MAX_VALUE;

			for ( var i : int = 0; i < list.listItems.length; i++ )
			{
				var item : SmallCartItem = list.listItems[i] as SmallCartItem;
				var delta : Number = ( item.x + item.width / 2 ) + list.list.content.x;

				if ( delta > 0 && delta < minDistance )
				{
					closest = item;
					minDistance = delta;
				}
			}

			if ( closest )
			{
				_selectedIndex = list.listItems.indexOf ( closest );
				applySelection( { time : 1, ease : Back.easeOut } );
			}
		}

		protected function handleArrowScroll ( evt : ButtonEvent ) : void
		{
			var delta : int = evt.target == leftBtn ? -1 : 1;
			selectedIndex += delta;
		}

	}
}
