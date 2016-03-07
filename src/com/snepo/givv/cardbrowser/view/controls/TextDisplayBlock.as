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
	
	public class TextDisplayBlock extends Component implements IListItem
	{

		public function TextDisplayBlock()
		{
			super();
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );
		}

		override protected function render ( ) : void
		{
			refresh();
		}

		public function refresh ( ) : void
		{
			var heading : String = data.heading || "";
			var body : String = data.body || "";

			if ( !heading.length )
			{
				headerField.visible = false;
				bodyField.y = 0;
			}else
			{
				headerField.htmlText = heading + "";
				headerField.height = headerField.textHeight + 5;
				bodyField.y = headerField.y + headerField.height + 5;
			}

			bodyField.htmlText = body;
			bodyField.height = bodyField.textHeight + 10;

			_height = bodyField.y + bodyField.height;
		}

	}
}
			
