package com.snepo.givv.cardbrowser.view.core
{
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class BackGround extends MovieClip
	{
		protected var _image : Loader = new Loader();

		public function BackGround()
		{
		}

		public function loadImage( filename : String )
		{
			if (filename == null || filename.length == 0)
				return;

			// load image
			_image.contentLoaderInfo.addEventListener ( Event.COMPLETE, onImageLoaded );
			_image.contentLoaderInfo.addEventListener ( IOErrorEvent.IO_ERROR, onImageError );
			_image.load( new URLRequest ( filename ) );
		}

		protected function onImageLoaded ( evt : Event ) : void
		{
			// add the Loader instance to the display list
			_image.alpha = 0;
			addChild ( _image );
			TweenMax.to ( _image, 1, { autoAlpha : 1, ease : Quint.easeInOut } );
		}

		protected function onImageError ( evt : ErrorEvent ) : void
		{
			Logger.log ( "Error loading image " + evt.text, Logger.ERROR );
			Controller.getInstance().report ( 50, "Failed to load background image" );
		}
	}
}



