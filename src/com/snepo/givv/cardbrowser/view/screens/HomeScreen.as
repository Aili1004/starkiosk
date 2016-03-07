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

	public class HomeScreen extends Screen
	{
		private static const BLUE_BUTTON   : int = 0;
		private static const YELLOW_BUTTON : int = 1;
		private static const RED_BUTTON :    int = 2;

		public var logo : MovieClip;
		public var blueButton : MovieClip;
		public var redButton : MovieClip;
		public var yellowButton : MovieClip;

		protected var boxes : Array = [];
		protected var balanceFooter : MovieClip;

		protected var view : View;

		public function HomeScreen ( )
		{
			super();

			view = View.getInstance();
			_width = View.APP_WIDTH;
			_height = View.APP_HEIGHT;

			_prompt = "";

			invalidate();
		}

		override protected function createUI ( ) : void
		{
			super.createUI();
			initHomePage();
		}

		protected function initHomePage() : void
		{
			var starHome : MovieClip = new StarHome();
			addChild(starHome);

			var swipeCardImg : MovieClip = new SwipeCardImg();
			addChild(swipeCardImg);

			starHome.HowToJoin.addEventListener ( MouseEvent.CLICK, showJoinPage );
			starHome.header.addEventListener ( MouseEvent.CLICK, goToMainPage );
			starHome.starAssist.addEventListener ( MouseEvent.CLICK, starAssistPage );
			starHome.responsibleGambling.addEventListener ( MouseEvent.CLICK, responsibleGamblingPage );
		}

		protected function showJoinPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.HOWTOJOIN_SCREEN;
		}

		protected function goToMainPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.CHOOSE_SCREEN;
		}

		protected function starAssistPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.STAR_CLUB_ASSIST_SCREEN;
		}

		protected function responsibleGamblingPage( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.RESPONSIBLE_GAMBLING_SCREEN;
		}

		protected function performFilter ( evt : MouseEvent ) : void
		{
			view.currentScreenKey = View.CHOOSE_SCREEN;

			var choose : ChooseScreen = view.getScreen ( View.CHOOSE_SCREEN ) as ChooseScreen;
			choose.filterButtons.selectById ( int((( evt.currentTarget as Object ).parent as MovieClip).searchType) );
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();
		}
	}
}
