package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.snepo.powermate.events.*;
	import com.snepo.powermate.*;
	import com.adobe.images.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.net.*;

	public class Coverflow extends Component
	{

		protected var _images : Array = [];
		protected var _filterType : int = 0;
		protected var _currentFilter : Array = [];
		protected var _sortList : Array = [];
		protected var _dataProvider : Array = [];
		protected var imageHolder : Sprite;

		protected var imagesToLoad : int = 0;
		protected var imagesLoaded : int = 0;

		protected var _selectedIndex : int = -1;
		protected var dragging : Boolean = false;
		protected var startIndex : int = -1;
		protected var touchPoint : Point = new Point();
		protected var lastPoint : Point = new Point();

		protected var frameTick : int = 0;

		protected var scrollbar : Scrollbar;
		protected var leftBtn : Button;
		protected var rightBtn : Button;

		public var primaryCoverflow : Boolean = false;

		protected var pm : PowermateManager;
		protected var mate : Powermate;
		protected var tapVoided : Boolean = false;

		protected var view : View;

		public function Coverflow()
		{
			super();

			view = View.getInstance();

			var pp : PerspectiveProjection = new PerspectiveProjection();
				pp.projectionCenter = new Point ( View.APP_WIDTH / 2, 0 );

			this.transform.perspectiveProjection = pp;
		}

		public function set filterByCardType ( type : String ) : void
		{
			this.dataProvider = model.cards.getCardsByType ( type );
		}

		public function slideToCard( card : Object ) : void
		{
			for each ( var cfi : CoverflowImage in _images )
			{
				if (card == cfi.data)
				{
					selectedIndex = cfi.index;
					return;
				}
			}
			selectFirst();
		}

		protected function onPowermateManagerConnectionError ( evt : PowermateEvent ) : void
		{
			Logger.log ( "Error connecting to powermate manager. ", Logger.ERROR );
		}

		protected function onPowermateManagerConnected ( evt : PowermateEvent ) : void
		{
			Logger.log ( "Connected to powermate manager. NumDevices=" + pm.numDevices );
		}

		protected function onPowermateDevicesReceived ( evt : PowermateEvent ) : void
		{
			if ( pm.numDevices > 0 )
			{
				mate = pm.devices[0];
				mate.addEventListener ( PowermateEvent.ROTATE, handlePowermateInput );
				mate.addEventListener ( PowermateEvent.PRESS, handlePowermateInput );
				mate.addEventListener ( PowermateEvent.HOLD, handlePowermateInput );
				mate.flash(10, 0.1);

				Logger.log ( "Found powermate '" + mate.name + "'." );

			}
		}

		protected function handlePowermateInput ( evt : PowermateEvent ) : void
		{
			switch ( evt.type )
			{
				case PowermateEvent.ROTATE :
				{
					var delta : int = evt.delta < 0 ? -1 : 1;
					selectedIndex += delta;
					break;
				}

				case PowermateEvent.PRESS :
				{
					if ( !(view.modalOverlay.currentContent is AddCardsOverlay) )
					{
						view.modalOverlay.currentContent = new AddCardsOverlay();
					}

					mate.flash ( 3, 0.1 );
					break;
				}

				case PowermateEvent.HOLD :
				{
					view.modalOverlay.hide();
					break;
				}
			}
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );

			imageHolder.addEventListener ( MouseEvent.MOUSE_DOWN, startDragging );
			imageHolder.addEventListener ( MouseEvent.MOUSE_MOVE, triggerMotion );
			stage.addEventListener ( MouseEvent.MOUSE_UP, stopDragging );
		}

		protected function startDragging ( evt : MouseEvent ) : void
		{
			if ( Environment.FIRST_USER && _images.length > 1 )
			{
				view.showSwipeOverlay();
			}

			tapVoided = false;

			dragging = true;
			startIndex = selectedIndex;

			touchPoint = new Point ( this.mouseX, this.mouseY );
			lastPoint = touchPoint.clone();
		}

		protected function triggerMotion ( evt : MouseEvent ) : void
		{
			if ( dragging && !hasEventListener ( Event.ENTER_FRAME ) )
			{
				addEventListener ( Event.ENTER_FRAME, handleDragging );
				tapVoided = true;
			}
		}

		protected function stopDragging ( evt : MouseEvent ) : void
		{
			var wasDragging : Boolean = dragging;

			removeEventListener ( Event.ENTER_FRAME, handleDragging );
			dragging = false;

			if ( wasDragging )
			{
				var throwDelta : int = ( this.mouseX - lastPoint.x ) / 10;
				this.selectedIndex -= throwDelta;
			}
		}

		protected function handleDragging ( evt : Event ) : void
		{
			var xDelta : int = ( this.mouseX - touchPoint.x ) / ( images.length * 2 );
			this.selectedIndex = startIndex - xDelta;

			if ( ++frameTick % 2 == 0 )
			{
				lastPoint = new Point ( this.mouseX, this.mouseY );
			}
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );
			addChild ( imageHolder = new Sprite() );
			addChild ( scrollbar = new Scrollbar() );
			/*addChild ( leftBtn = new Button() );*/
			/*addChild ( rightBtn = new Button() );*/
			leftBtn = new Button();
			rightBtn = new Button();

			/*leftBtn.setSize ( 80, 80 );
			leftBtn.label = "";
			leftBtn.icon = new LeftArrowIcon();
			leftBtn.repeating = true;
			leftBtn.repeatRate = 300;
			leftBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );*/

			/*rightBtn.setSize ( 80, 80 );
			rightBtn.label = "";
			rightBtn.icon = new RightArrowIcon();
			rightBtn.repeating = true;
			rightBtn.repeatRate = 300;
			rightBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );*/

			scrollbar.orientation = Scrollbar.HORIZONTAL;
			scrollbar.width = 281;
			scrollbar.addEventListener ( ScrollEvent.SCROLL, updateIndexFromScroll );
			scrollbar.addEventListener ( ScrollEvent.SNAP, updateIndexFromScroll );
			scrollbar.visible = false;
		}

		protected function performSelect ( evt : * = null ) : void
		{
			dispatchEvent ( new Event ( Event.SELECT ) );
		}

		protected function handleArrowScroll ( evt : ButtonEvent ) : void
		{
			var delta : int = evt.target == leftBtn ? -1 : 1;
			selectedIndex += delta;
		}

		protected function updateIndexFromScroll ( evt : ScrollEvent ) : void
		{
			var value : Number = evt.type == ScrollEvent.SNAP ? evt.value : scrollbar.value;
			var index : int = value * ( _currentFilter.length );

			selectedIndex = index;
		}

		protected function updateArrows ( ) : void
		{
			if (_currentFilter.length == 1)
				rightBtn.visible = leftBtn.visible = false;
			else
			{
				rightBtn.visible = leftBtn.visible = true;
				if ( _currentFilter.length > 1 && selectedIndex < _currentFilter.length - 1 )
				{
					rightBtn.enabled = true;
				}else
				{
					rightBtn.enabled = false;
				}
				if ( _currentFilter.length > 1 && selectedIndex > 0 )
				{
					leftBtn.enabled = true;
				}else
				{
					leftBtn.enabled = false;
				}
				if ( _currentFilter.length == 0 )
				{
					leftBtn.enabled = rightBtn.enabled = false;
				}
			}
		}

		public function set dataProvider ( d : Array ) : void
		{
			this._dataProvider = d;
			this.render();
		}

		public function get dataProvider ( ) : Array
		{
			return this._dataProvider;
		}

		public function get images ( ) : Array
		{
			return _images;
		}

		override public function dispose ( ) : void
		{
			super.dispose();

			for each ( var cfi : CoverflowImage in _images )
			{
				cfi.dispose();
				cfi.destroy();
			}

			_images = [];
			_sortList = [];
			_currentFilter = [];
		}

		override protected function render ( ) : void
		{
			dispose();

			trace ( "rendering " + dataProvider.length );

			imagesLoaded = 0;
			imagesToLoad = dataProvider.length;

			for ( var i : int = 0; i < dataProvider.length; i++ )
			{
				var image : CoverflowImage = new CoverflowImage();
					image.index = i;
					image.addEventListener ( MouseEvent.MOUSE_DOWN, slideToImage, false, 0, true );
					image.addEventListener ( Event.COMPLETE, onImageLoaded, false, 0, true );
					image.addEventListener ( MouseEvent.CLICK, selectFrontmostImage, false, 0, true );
					image.data = dataProvider[i];

				imageHolder.addChild ( image );
				_images.push ( image );
				_sortList.push ( image );
				_currentFilter.push ( image );
			}

			layout();
			selectedIndex = 0;
			TweenMax.delayedCall ( 1, selectFirst );

		}

		protected function selectFirst ( ) : void
		{
			layout();
			selectedIndex = 0;
		}

		protected function slideToImage ( evt : MouseEvent ) : void
		{

			var oldIndex : int = selectedIndex;

			var clicked : CoverflowImage = evt.currentTarget as CoverflowImage;
			selectedIndex = clicked.index;
		}

		protected function selectFrontmostImage ( evt : MouseEvent ) : void
		{
			var clicked : CoverflowImage = evt.currentTarget as CoverflowImage;
			if ( clicked.index == selectedIndex)
			{
				performSelect();
			}
		}

		protected function onImageLoaded ( evt : Event ) : void
		{
			var image : CoverflowImage = evt.target as CoverflowImage;
				image.removeEventListener ( Event.COMPLETE, onImageLoaded );

			imagesLoaded++;
			if ( imagesLoaded >= imagesToLoad )
			{
				layout();
				if ( imagesToLoad > 1 )
				{
					selectedIndex = 1;
					selectedIndex = 0;
				}else
				{
					selectedIndex = 0;
				}
				invalidate();
			}
		}

		protected function layout ( animated : Boolean = false ) : void
		{
			var lastX : Number = 0;
			for ( var i : int = 0; i < _currentFilter.length; i++ )
			{
				var image : CoverflowImage = _currentFilter[i];
					image.x = lastX;
				if ( i > 0 )
				{
					var previous : CoverflowImage = _currentFilter [ i - 1 ] as CoverflowImage;
					if ( animated )
					{
						TweenMax.to ( image, 0.5, { x : lastX + previous.width - 150, ease : Quint.easeOut, delay : i / 30 } );
						lastX = lastX + previous.width - 150;

					}else
					{
						image.x = previous.x + previous.width - 150;
					}
				}
			}
		}

		public function set filterType ( bitMask : int ) : void
		{
			_filterType = bitMask;

			_currentFilter = [];

			var inCtr : int = 0;
			var outCtr : int = 0;
			var i : int;

			var isAllCards : Boolean = bitMask == CategoryModel.ALL_CATEGORIES;

			//trace ( "bitMask : " + bitMask + " : " + isAllCards );

			for ( i = 0; i < _images.length; i++ )
			{
				var image : CoverflowImage = _images[i];
				var flag : int = image.data.categoryBits;

				if ( BitUtil.match ( bitMask, flag ) || isAllCards )
				{
					image.index = inCtr;
					image.setInFilter ( true, inCtr / 60 );
					inCtr++;
					_currentFilter.push ( image );

				}else
				{
					image.setInFilter ( false, outCtr / 150 );
					outCtr++;
				}
			}

			layout ( false );
			selectedIndex = 0;
		}

		public function get filterType ( ) : int
		{
			return _filterType;
		}

		public function set selectedIndex ( i : int ) : void
		{
			if ( i < 0 ) i = 0;
			if ( i > _currentFilter.length - 1 ) i = _currentFilter.length - 1;

			var changed : Boolean = i != _selectedIndex;
			_selectedIndex = i;
			applySelection( changed );
		}

		public function get selectedIndex ( ) : int
		{
			return _selectedIndex;
		}

		public function get selectedImage ( ) : CoverflowImage
		{
			return images [ selectedIndex ];
		}

		protected function applySelection ( hasChanged : Boolean = true ) : void
		{
			updateArrows();

			var currentImage : CoverflowImage = _currentFilter[selectedIndex];

			var time : Number = !dragging ? 0.6 : 0.6;

			if ( !currentImage ) return;

			// Select card if only one in category
			if (view.currentScreenKey == View.CHOOSE_SCREEN && _currentFilter.length == 1 && !(view.modalOverlay.currentContent is AddCardsOverlay) )
				view.modalOverlay.currentContent = new AddCardsOverlay();

			if ( primaryCoverflow ) model.cards.selectedCard = currentImage.data;

			for ( var i : int = 0; i < _currentFilter.length; i++ )
			{
				var image : CoverflowImage = _currentFilter[i] as CoverflowImage;
					image.applyDelta ( image.index - selectedIndex, time );
			}

			_sortList.sort ( zsort );
			reparent();

			currentImage.parent.addChild ( currentImage );

			var offset : Number = -currentImage.x + width / 2;

			TweenMax.killTweensOf ( imageHolder );
			TweenMax.to ( imageHolder, time, { x : offset, ease : Quint.easeOut } );

			scrollbar.silentValue = selectedIndex / _currentFilter.length;
		}

		protected function reparent ( ) : void
		{
			for ( var i : int = 0; i < _sortList.length; i++ )
			{
				var image : CoverflowImage = _sortList[i] as CoverflowImage;
					image.parent.addChildAt ( image, i );
			}
		}

		protected function zsort ( a : CoverflowImage, b : CoverflowImage ) : int
		{
			var deltaA : int = Math.abs ( a.currentDelta );
			var deltaB : int = Math.abs ( b.currentDelta );

			if ( deltaA > deltaB ) return -1;
			if ( deltaB > deltaA ) return 1;
			return 0;
		}

		override protected function invalidate ( ) : void
		{
			applySelection();

			if ( scrollbar )
			{
				scrollbar.x = width / 2 - scrollbar.width / 2;
				scrollbar.y = 200;
			}

			if ( leftBtn )
			{
				leftBtn.x = (width / 2) - leftBtn.width - 80
				leftBtn.y = 130

				rightBtn.x = (width / 2) + 80
				rightBtn.y = leftBtn.y
			}
		}

		public function get filteredImageCount ( ) : int
		{
			return _currentFilter.length;
		}

	}
}
