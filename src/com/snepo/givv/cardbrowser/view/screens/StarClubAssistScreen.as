package com.snepo.givv.cardbrowser.view.screens
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.overlays.*;
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
	import flash.utils.*;
	import flash.geom.*;
	import flash.text.*;

	public class StarClubAssistScreen extends Screen
	{

		public function StarClubAssistScreen ( )
		{
			var starClubAssistPage : MovieClip = new StarClubAssistPage();
			addChild(starClubAssistPage);

			var closeIcon : MovieClip = new CloseIcon();
			addChild(closeIcon);

			closeIcon.closeBtn.addEventListener ( MouseEvent.CLICK, closeCurrentPage );

			var backIcon : MovieClip = new BackIcon();
			addChild(backIcon);

			backIcon.backBtn.addEventListener (MouseEvent.CLICK, goToKeyboardPage);
		}

		protected function closeCurrentPage( evt : MouseEvent ) : void
		{
			View.getInstance().currentScreenKey = View.HOME_SCREEN;
		}
		protected function goToKeyboardPage( evt : MouseEvent ) : void
		{
			View.getInstance().currentScreenKey = View.STAR_KEYBOARD_SCREEN;
		}

	}
}
