package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class FilterButtonBar extends ButtonBar
	{

		protected var leftRamp : MovieClip;
		protected var rightRamp : MovieClip;

		protected var leftBtn : Button;
		protected var rightBtn : Button;

    	public function FilterButtonBar()
		{
			super();
			_useHtml = true;
			verticalScrollEnabled = false;
			horizontalScrollEnabled = false;
		}

		override protected function createUI ( ) : void
		{
			super.createUI();

			addRogueChild ( leftRamp = new EdgeRamp() );
			addRogueChild ( rightRamp = new EdgeRamp() );

			addRogueChild ( leftBtn = new Button() );
			addRogueChild ( rightBtn = new Button() );

			leftBtn.setSize ( 60, 60 );
			leftBtn.label = "";
			leftBtn.icon = new LeftArrowIcon();
			leftBtn.repeating = true;
			leftBtn.repeatRate = 300;
			leftBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );

			rightBtn.setSize ( 60, 60 );
			rightBtn.label = "";
			rightBtn.icon = new RightArrowIcon();
			rightBtn.repeating = true;
			rightBtn.repeatRate = 300;
			rightBtn.addEventListener ( ButtonEvent.REPEAT, handleArrowScroll );

			leftRamp.mouseEnabled = leftRamp.mouseChildren = false;
			rightRamp.mouseEnabled = rightRamp.mouseChildren = false;

			invalidate();
		}

		protected function handleArrowScroll ( evt : ButtonEvent ) : void
		{
			var delta : int = evt.target == rightBtn ? 1 : -1;
			selectedIndex += delta;
		}

		override protected function render ( ) : void
		{
			super.render();
			updateArrowsAndRamps();
			selectedIndex = 0;
		}

		override protected function toggleSelection ( evt : MouseEvent = null, forceItem : Button = null, silent : Boolean = false ) : void
		{
			if ( tapVoided ) return;

			super.toggleSelection ( evt, forceItem, silent );
			var item : Button = buttons[selectedIndex];

			if ( item && content.width > width )
			{
				var offset : Number = -item.x + width / 2 - item.width / 2;
				TweenMax.to ( content, 0.5, { x : offset, ease : Quint.easeOut } );
			}

			updateArrowsAndRamps();
		}

		protected function updateArrowsAndRamps() : void
		{
			if ( content.width > width )
			{
				leftRamp.visible = true;
				rightRamp.visible = true;

				leftBtn.visible = true;
				rightBtn.visible = true;
			}else
			{
				leftRamp.visible = false;
				rightRamp.visible = false;

				leftBtn.visible = false;
				rightBtn.visible = false;
			}

			leftBtn.enabled = selectedIndex > 0;
			rightBtn.enabled = selectedIndex < buttons.length - 1;


		}

		public function get flag ( ) : int
		{
			return buttons [ selectedIndex ].data.flag;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			if ( leftRamp )
			{
				leftRamp.x = -10;
				leftRamp.y = -10;
				leftRamp.height = height + 20;

				rightRamp.rotation = 180;
				rightRamp.height = height + 20;
				rightRamp.x = width;
				rightRamp.y = height + 10;

				leftBtn.x = 5;
				leftBtn.y = height / 2 - leftBtn.height / 2;

				rightBtn.x = width - rightBtn.width - 5;
				rightBtn.y = height / 2 - leftBtn.height / 2;

			}
		}
	}

}
