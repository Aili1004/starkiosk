package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.events.*;
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

	public class ModalOverlay extends Component
	{
		protected var _currentContent : Component;

		protected var contentHolder : Sprite;
		protected var contentMask : Sprite;
		protected var backing : Sprite;

		protected var isShown : Boolean = false;
		protected var blocker : Sprite;
		protected var _forceCloseRequested : Boolean = false;

		public function ModalOverlay()
		{
			super();

			_height = View.APP_HEIGHT;

			invalidate();
		}

		override protected function initStageEvents ( evt : Event = null ) : void
		{
			super.initStageEvents ( evt );
		}

		protected function onSwipeGesture ( g : Gesture ) : void
		{
			hide();
		}

		public function get canClose ( ) : Boolean
		{
			if ( currentContent && ( currentContent is IOverlay ) )
			{
				var overlayCanClose : Boolean = ( currentContent as IOverlay ).canClose;
				if ( !overlayCanClose )
				{
					return false;
				}
			}

			return true;
		}

		public function set currentContent ( c : Component ) : void
		{
			Logger.log ( "Showing overlay: " + flash.utils.getQualifiedClassName(c).split("::")[1] );

			if ( !canClose )
			{
				if ( currentContent is IOverlay )
				{
					( currentContent as IOverlay ).onRequestClose();
					return;
				}
			}

			if ( currentContent )
			{
				hideCurrentContent ( currentContent )
			}

			DisplayUtil.top ( this );

			_currentContent = contentHolder.addChild ( c ) as Component;
			_currentContent.x = contentMask.x + contentMask.width + 10;
			if (_currentContent.canShow)
			{
				isShown = true;
				TweenMax.to ( this, 0.6, { width : c.width + 40, ease : Quint.easeInOut } );
				TweenMax.to ( _currentContent, 0.6, { x : 0, ease : Quint.easeInOut } );

				if ( ( currentContent as Object ).hasOwnProperty ( "isSuperModal" ) )
				{
					makeModal( ( currentContent as Object).isSuperModal );
				}else
				{
					makeModal ( false );
				}
			}
		}

		protected function makeModal ( isModal : Boolean ) : void
		{
			TweenMax.killDelayedCallsTo ( makeModal );

			var a : Number = isModal ? 1 : 0;
			TweenMax.killTweensOf ( blocker );
			TweenMax.to ( blocker, 0.6, { autoAlpha : a, ease : Quint.easeInOut } );
		}

		public function get currentContent ( ) : Component
		{
			return _currentContent;
		}

		protected function hideCurrentContent ( c : Component ) : void
		{
			if (isShown)
				TweenMax.to ( c, 0.6, { x : -c.width - 50, ease : Quint.easeInOut, onComplete : destroyContent, onCompleteParams : [ c ] } );
			else
				destroyContent(c);
		}

		protected function destroyContent ( c : Component ) : void
		{
			c.dispose();
			c.destroy();

			DisplayUtil.remove ( c );
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );

			addChild ( backing = new Sprite() );
			addChild ( contentHolder = new Sprite( ) );
			addChild ( contentMask = new Sprite() );
			addChildAt ( blocker = new Sprite(), 0 );

			contentHolder.mask = contentMask;

			var g : Graphics;

			g = backing.graphics;
			g.beginFill ( 0x000000, 0.9 );
			g.drawRect ( 0, 0, 10, 10 );
			g.endFill();

			g = contentMask.graphics;
			g.beginFill ( 0xFF0000, 0.4 );
			g.drawRect ( 0, 0, 10, 10 );
			g.endFill();

			g = blocker.graphics;
			g.beginFill ( 0x000000, 0.4 );
			g.drawRect ( 0, 0, 1624, 768 );
			g.endFill();

			blocker.x = -blocker.width;
			blocker.alpha = 0;
			blocker.visible = false;

			invalidate();
		}

		public function show ( delay : Number = 0 ) : void
		{
			isShown = true;
			TweenMax.to ( this, 0.6, { x : View.APP_WIDTH + this.width + 10, ease : Quint.easeInOut, delay : delay } );
		}

		public function hide ( delay : Number = 0 ) : void
		{
			if ( !_forceCloseRequested )
			{
				if ( !canClose )
				{
					if ( currentContent is IOverlay )
					{
						( currentContent as IOverlay ).onRequestClose();
						return;
					}
				}
			}

			isShown = false;
			TweenMax.to ( this, 0.6, { x : View.APP_WIDTH + this.width + 10, width : 0, ease : Quint.easeInOut, delay : delay } );
			TweenMax.delayedCall ( delay, makeModal, [ false ] );
			if ( currentContent ) hideCurrentContent( currentContent );
			_currentContent = null;
		}

		public function forceClose ( ) : void
		{
			_forceCloseRequested = true;
			hide();
			_forceCloseRequested = false;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate ( );

			backing.width = width;
			backing.height = height;

			contentHolder.x = 20;
			contentHolder.y = 20;

			contentMask.x = 20;
			contentMask.y = 20;
			contentMask.width = width - 40;
			contentMask.height = height - 40;

			if ( currentContent )
			{
				currentContent.width = width - 45;
			}

			if ( isShown )
			{
				this.x = View.APP_WIDTH - this.width;
			}
		}

	}
}