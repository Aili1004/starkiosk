package com.snepo.givv.cardbrowser.view.controls
{	
	/**
	* @author Andrew Wright
	*/
	
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
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
	import flash.net.*;
	
	public class MiniCartItem extends Component implements IListItem
	{
		protected var icon : Bitmap;

		public function MiniCartItem ()
		{
			super();

			_width = 400;
			_height = 68;
		}

		public function refresh ( ) : void
		{
			dispose();
			render();
		}

		override protected function render ( ) : void
		{

			addChild ( icon = new Bitmap ( ImageCache.getInstance().getIcon ( data.card.id ), PixelSnapping.AUTO, true ) );
			DisplayUtil.smooth ( icon );

			icon.width = 84;
			icon.height = 53;

			nameField.text = data.card.name;
			nameField.width = nameField.textWidth + 5;
			nameField.y = icon.height / 2 - nameField.height / 2;
		}

		override public function dispose ( ) : void
		{
			trace ( "DISPOSING MINICARTITEM")
			super.dispose();
			DisplayUtil.disposeBitmap ( icon );
			icon = null;


		}

	}
}