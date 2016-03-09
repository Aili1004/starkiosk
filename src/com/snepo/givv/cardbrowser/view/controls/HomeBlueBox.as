package com.snepo.givv.cardbrowser.view.controls
{
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

	public class HomeBlueBox extends MovieClip
	{
		public var searchType : int;

		public function autoResize ( buttonCount : int, drawCount : int ) : void
		{
			infoBtn.buttonCount = buttonCount;
			if (buttonCount == 1)
			{
				// enlarge colour button
				colorBtn.x = colorBtn.x - (colorBtn.width/2);
				colorBtn.scaleX = 2;
				// widen text fields
				infoBtn.textFieldsX = colorBtn.x;
				infoBtn.textFieldsWidth = colorBtn.width*2;
				// make whole screen touchable for this button
				bigBtn.x = bigBtn.x - (View.APP_WIDTH / 2) - (bigBtn.width / 2);
				bigBtn.y = bigBtn.y - 250;
				bigBtn.scaleX = View.APP_WIDTH / bigBtn.width;
			}
			else if (buttonCount == 2)
			{
				// reposition (fudged as I'm not good a maths!)
				x = ((View.APP_WIDTH / 2) - (((width * 1.15 * buttonCount) + (50 * (buttonCount-1))) / 2)) + // center all buttons
	           (width * 1.2 * drawCount) + (70 * drawCount); // offset this button within the button block
				// enlarge colour buttons
				colorBtn.x = colorBtn.x - ((colorBtn.width * 0.2) / 2);
				colorBtn.scaleX = 1.2;
				bigBtn.x = colorBtn.x;
				bigBtn.scaleX = 6.5; // This works. I have given up trying to work out why.
				// widen text fields
				infoBtn.textFieldsX = colorBtn.x;
				infoBtn.textFieldsWidth = colorBtn.width * 1.2;
			}
		}
	}
}