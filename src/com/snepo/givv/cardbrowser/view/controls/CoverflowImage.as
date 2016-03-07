package com.snepo.givv.cardbrowser.view.controls
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;
	
	import com.greensock.easing.*;
	import com.greensock.*;
	
	import flash.filters.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	
	public class CoverflowImage extends Component
	{

		protected var _loader : Loader;
		public var index : int;
		
		protected var _currentDelta : int = 1000;
		protected var shadow : DropShadowFilter;
		protected var _inFilter : Boolean = true;
		protected var _spinner : Spinner;
		protected var _imageMask : Sprite;
		protected var watermark : MovieClip;

		protected var _image : Bitmap;
		protected var holder : Sprite;
		
		public function CoverflowImage()
		{
			shadow = new DropShadowFilter ( 15, 90, 0x000000, 0.5, 10, 10, 1, 3 )

			super();
						
			_width = 339;
			_height = 215;

			buttonMode = true;
			mouseChildren = false;
		}

		override protected function createUI ( ) : void
		{
			super.createUI ( );
			
			addChild ( _spinner = new Spinner() );
					   _spinner.filters = [ new GlowFilter ( 0x000000, 0.3 ) ];

			addChild ( _imageMask = new Sprite() );
			addChild ( holder = new Sprite() );
			
		}
		
		public function setInFilter ( inFilter : Boolean, delay : Number = 0 ) : void
		{
			_inFilter = inFilter;
			var alpha : Number = inFilter ? 1 : 0;
			var y : Number = inFilter ? 0 : -250;
			var ease : Function = inFilter ? Back.easeOut : Back.easeIn;
			
			var tweenParams : Object = {};
				tweenParams.y = y;
				tweenParams.ease = ease;
				tweenParams.delay = delay;
				tweenParams.autoAlpha = alpha;
			
			TweenMax.killTweensOf ( this );
			TweenMax.to ( this, 0.3, tweenParams );
		}
		
		public function applyDelta ( d : int, time : Number ) : void
		{
			if ( d == _currentDelta ) return;

			_currentDelta = d;

			var yRot : Number = d * 30;
			if ( yRot < -90 ) yRot = -90;
			if ( yRot > 90 ) yRot = 90;

			var newZ : Number = Math.abs ( d ) * 150;
			if ( d == 0 ) newZ = -50;
			
			TweenMax.to ( this, time, { rotationY : yRot, z : newZ, ease : Quint.easeOut } );
		}
		
		public function get currentDelta ( ) : int
		{
			return _currentDelta;
		}
		
		override protected function render ( ) : void
		{
			dispose();

			_spinner.visible = true;
			
			_spinner.play();
			
			holder.addChild ( _image = new Bitmap ( ImageCache.getInstance().getImage ( data.id ), PixelSnapping.AUTO, true ) );
			holder.filters = [shadow];
			
			DisplayUtil.smooth ( _image );

			TweenMax.delayedCall ( 0.1, onComplete );

			if ( data.processas == CardModel.SCANNABLE )
			{
			}

		}
		
		protected function onImageLoaded ( evt : Event ) : void
		{
			DisplayUtil.smooth ( _loader );
			
			_loader.contentLoaderInfo.removeEventListener ( Event.COMPLETE, onImageLoaded );
			_loader.contentLoaderInfo.removeEventListener ( IOErrorEvent.IO_ERROR, onImageError );
			
			onComplete();
		}

		protected function onComplete ( ) : void
		{
			_image.x = -_image.width / 2;
			_image.y = -_image.height / 2;

			drawMask();

			scaleX = 0;
			scaleY = 0;

			TweenMax.to ( this, 0.3, { scaleX : 1, scaleY : 1, ease : Back.easeOut } );

			_spinner.visible = false;
			_spinner.stop();
			
			dispatchEvent ( new Event ( Event.COMPLETE ) );
		}

		protected function drawMask ( ) : void
		{
			var g : Graphics = _imageMask.graphics;
				g.clear();
				g.beginFill ( 0xFF0000, 0.5 );
				g.drawRoundRectComplex ( 0, 0, _image.width, _image.height, 10, 10, 10, 10 );
				g.endFill();

			_imageMask.x = _image.x;
			_imageMask.y = _image.y;
			holder.mask = _imageMask;
		}
		
		protected function onImageError ( evt : ErrorEvent ) : void
		{
			_loader.contentLoaderInfo.removeEventListener ( Event.COMPLETE, onImageLoaded );
			_loader.contentLoaderInfo.removeEventListener ( IOErrorEvent.IO_ERROR, onImageError );
			
			//Logger.log ( "image error : " + Dumper.toString ( this.data ) );
		}
		
		override public function dispose ( ) : void
		{
			//DisplayUtil.disposeLoader ( _loader );
			DisplayUtil.disposeBitmap ( _image );
			
			_image = null;
		}
		
		override public function destroy ( ) : void
		{
			DisplayUtil.remove ( this );
		}
		
		

	}
}