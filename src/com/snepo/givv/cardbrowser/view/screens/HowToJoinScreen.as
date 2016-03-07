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

	public class HowToJoinScreen extends Screen
	{
		var closeIcon : MovieClip = new CloseIcon();

		public function HowToJoinScreen ( )
		{
			var starJoinPage : MovieClip = new StarJoinPage();
			addChild(starJoinPage);

			addChild(closeIcon);
			closeIcon.closeBtn.addEventListener ( MouseEvent.CLICK, closeCurrentPage );
		}

		protected function closeCurrentPage(evt : MouseEvent) : void
		{
			View.getInstance().currentScreenKey = View.HOME_SCREEN;
		}
	}
}
