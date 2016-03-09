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
		
	public class BigIconButton extends Button
	{
		protected var _subLabel : String = "";
		protected var _valid : Boolean = true;
		protected var subLabelField : TextField;
		protected var _bigIcon : MovieClip;

		public function BigIconButton ( ) 
		{
			super();

			mouseChildren = true;
			cornerRadii = { tr : 10, tl : 10, br : 10, bl : 10 };
		}

		override protected function createUI ( ) : void
		{
			super.createUI();
			
			addChild ( subLabelField = new TextField() );

			var tf : TextFormat = labelField.getTextFormat();
				tf.size = 16;
				tf.align = "center"
				tf.font = new Environment.font.fontName;

			subLabelField.defaultTextFormat = tf;
			subLabelField.filters = [ labelField.filters[0] ];
			subLabelField.antiAliasType = AntiAliasType.NORMAL;
			subLabelField.embedFonts = true;
			subLabelField.mouseEnabled = false;

			labelField.mouseEnabled = false;
		}

		override protected function render ( ) : void
		{
			var tf : TextFormat = labelField.getTextFormat();
				tf.leading = -1;	

			textFormat = tf;

			super.render();
			subLabel = data.subLabel;

			if ( data.valid )
			{
				onFillColor = 0x6c8e17;
				offFillColor = 0xADAFB2;
				onLabelColor = 0xFFFFFF;
				offLabelColor = 0xFFFFFF;
			}else
			{
				onFillColor = 0xADAFB2;
				offFillColor = 0xBD0000;
				onLabelColor = 0xFFFFFF;
				offLabelColor = 0xFFFFFF;
			}


			if ( _bigIcon ) DisplayUtil.remove ( _bigIcon );

			addChild ( _bigIcon = new data.icon() as MovieClip );
			_bigIcon.mouseEnabled = _bigIcon.mouseChildren = false;
			
			_bigIcon.x = width / 2 - _bigIcon.width / 2;
			_bigIcon.y = height / 2 - _bigIcon.height / 2 - 20;
			_bigIcon.filters = [ this.filters[0] ];

			applySelection();
			redraw();
		}

		public function set subLabel ( s : String ) : void
		{
			this._subLabel = s;
			this.renderSubLabel();
		}

		public function get subLabel ( ) : String
		{
			return this._subLabel;
		}

		protected function renderSubLabel ( ) : void
		{
			subLabelField.text = subLabel;
			subLabelField.width = subLabelField.textWidth + 4;
			subLabelField.visible = false;
		}

		override protected function invalidate ( ) : void
		{
			super.invalidate();

			if ( labelField && subLabelField )
			{
				subLabelField.x = width / 2 - subLabelField.width / 2 + 2;
				subLabelField.y = labelField.y + labelField.height + 30;

				labelField.width = width - 10;
				labelField.wordWrap = true;
				labelField.multiline = true;
				labelField.x = 5 + width / 2 - labelField.width / 2;
				labelField.height = labelField.textHeight + 5;
				
				if ( _bigIcon )
				{
					labelField.y = _bigIcon.y + _bigIcon.height + 8;
				}else
				{
					labelField.y = height - labelField.height - 10;
				}
			}

			if ( _bigIcon )
			{
				_bigIcon.x = width / 2 - _bigIcon.width / 2;
				_bigIcon.y = height / 2 - _bigIcon.height / 2;
			}
		}
	}
}