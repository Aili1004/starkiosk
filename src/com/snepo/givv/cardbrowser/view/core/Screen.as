package com.snepo.givv.cardbrowser.view.core
{
	import com.snepo.givv.cardbrowser.managers.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.util.*;
	import com.snepo.givv.cardbrowser.view.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;

	public class Screen extends Component
	{
		protected var _isShown : Boolean = false;
		protected var _screenKey : String;
		protected var _prompt : String = "";

		public function Screen()
		{
			super();
		}

		public function get prompt ( ) : String
		{
			return _prompt;
		}

		public function set screenKey ( s : String ) : void
		{
			_screenKey = s;
		}

		public function get screenKey ( ) : String
		{
			return _screenKey;
		}

		public function hideImmediately ( ) : void
		{
			this.visible = false;
		}

		public function show ( delay : Number = 0, notify : Boolean = true ) : void
		{
			TweenMax.killTweensOf ( this );

			this.scaleX = this.scaleY = 1.5;
			this.x = View.APP_WIDTH / 2 - ( ( scaleX * View.APP_WIDTH ) / 2 );
			this.y = View.APP_HEIGHT / 2 - ( ( scaleX * View.APP_HEIGHT ) / 2 );
			this.alpha = 0;

			TweenMax.to ( this, 0.5, { scaleX : 1, scaleY : 1, autoAlpha : 1, x : 0, y : 0, ease : Back.easeOut, delay : delay } );

			_isShown = true;

			if ( notify ) dispatchEvent ( new ScreenEvent ( ScreenEvent.SHOW, screenKey ) );

			this.onShow();

		}

		protected function onShow() : void
		{

		}

		public function hide ( delay : Number = 0, notify : Boolean = true ) : void
		{
			TweenMax.killTweensOf ( this );

			TweenMax.to ( this, 0.5, { scaleX : 0, scaleY : 0, autoAlpha : 0, x : View.APP_WIDTH / 2, y : View.APP_HEIGHT / 2, delay : delay, ease : Back.easeIn } );

			_isShown = false;

			if ( notify ) dispatchEvent ( new ScreenEvent ( ScreenEvent.HIDE, screenKey ) );

			this.onHide();
		}

		protected function onHide() : void
		{

		}

		public function get isShown ( ) : Boolean
		{
			return _isShown;
		}

	}
}
