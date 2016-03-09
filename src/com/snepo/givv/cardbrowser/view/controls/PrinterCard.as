package com.snepo.givv.cardbrowser.view.controls
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.core.*;
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

	public class PrinterCard extends Component
	{

		protected var _progress : Number = 0;

		public var image : Bitmap;
		public var fillImage : Bitmap;

		public var targetX : Number;
		public var targetY : Number;

		public function PrinterCard()
		{
			super();

			_width = 201;
			_height = 129;

			this.filters = [ new DropShadowFilter ( 3, 0, 0x000000, 0.3, 8, 0, 2, 2 ) ];

			filler.scaleX = 0;

		}

		public function killGlow ( ) : void
		{
			TweenMax.to ( this, 1, { dropShadowFilter : { alpha : 0 } } );
			TweenMax.to ( image, 1, { delay : 1, alpha : 0.1 } );
		}

		override public function dispose ( ) : void
		{
			DisplayUtil.disposeBitmap ( image );
			DisplayUtil.remove ( image );

			DisplayUtil.disposeBitmap ( fillImage );
			DisplayUtil.remove ( fillImage );

			image = null;
			fillImage;
		}

		override public function destroy ( ) : void
		{
			DisplayUtil.remove ( this );
		}

		override protected function render ( ) : void
		{
			imageHolder.addChild ( image = new Bitmap ( ImageCache.getInstance().getImage ( data.card.id, 0.64 ), PixelSnapping.AUTO, true ) ) ;
			imageHolder.addChild ( fillImage = new Bitmap ( ImageCache.getInstance().getImage ( data.card.id, 0.64 ), PixelSnapping.AUTO, true ) ) ;

			image.width = 201;
			image.height = 129;

			fillImage.width = 201;
			fillImage.height = 129;

			fillImage.mask = filler;
		}

		public function set progress ( p : Number ) : void
		{
			this._progress = p;
			this.applyProgress();
		}

		public function get progress ( ) : Number
		{
			return _progress;
		}

		protected function applyProgress ( ) : void
		{
			TweenMax.to ( filler, 0.8, { scaleX : progress / 100, ease : Quint.easeOut } );
		}

				
	}
}