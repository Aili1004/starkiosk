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
	
	public class TitleText extends Component
	{
		
		protected var currentText : MovieClip;
		protected var textHolder : Sprite;
		protected var masker : Sprite;
		
		protected var _title : String = "";
		protected var _textFormat : Object;
		protected var _literalTextFormat : TextFormat;
		protected var _textProperties : Object;
		
		public var measureSize : Boolean = true;

		public var center : Boolean = true;

		
		public function TitleText()
		{
			super();
		}

		public function set literalTextFormat ( lt : TextFormat ) : void
		{
			_literalTextFormat = lt;
		}

		public function get literalTextFormat ( ) : TextFormat
		{
			return _literalTextFormat;
		}

		public function set textFormat ( t : Object ) : void
		{
			_textFormat = t;
		}

		public function get textFormat ( ) : Object
		{
			return _textFormat;
		}

		public function set textProperties ( t : Object ) : void
		{
			_textProperties = t;
		}

		public function get textProperties ( ) : Object
		{
			return _textProperties;	
		}

		public function set textWidth ( t : Number ) : void
		{
			if ( currentText ) currentText.titleField.width = t;
		}
		
		public function set title ( t : String ) : void
		{
			TweenMax.killDelayedCallsTo ( clear );

			if ( currentText ) hideText ( currentText );
			
			_title = t;
			
			if ( !t ) return;
			
			currentText = new TitleTextField();

			if ( textFormat ) FontUtil.applyTextFormat ( currentText.titleField, textFormat );
			if ( textProperties ) FontUtil.applyProperties ( currentText.titleField, textProperties );
			if ( literalTextFormat ) 
			{
				currentText.titleField.defaultTextFormat = literalTextFormat;
				currentText.titleField.setTextFormat ( literalTextFormat );
			}

			currentText.titleField.text = t;

			if ( !measureSize )
			{
				currentText.titleField.width = width;				
				currentText.titleField.height = height;
			}else
			{
				var measuredTextWidth : Number = currentText.titleField.textWidth + 10;
				if ( measuredTextWidth > ( width - 10 ) ) measuredTextWidth = width - 10;

				currentText.titleField.width = measuredTextWidth;
				currentText.titleField.height = currentText.titleField.textHeight + 5;
			}
		
			currentText.y = -currentText.height - 10;
			
			TweenMax.to ( currentText, 0.4, { y : 0, ease : Back.easeOut, delay : 0.3 } );
			TweenMax.to ( this, 0.4, { height : currentText.titleField.height, ease : Back.easeOut, delay : 0.3 } );
			
			textHolder.addChild ( currentText );
			
			invalidate();
			
		}

		public function get nextHeight ( ) : Number
		{
			if ( !currentText ) return 5;
			return currentText.titleField.textHeight;
		}
		
		public function get title ( ) : String
		{
			return _title;
		}

		public function set temporaryTitle ( t : String ) : void
		{
			title = t;
			TweenMax.delayedCall ( 2, clear );
		}

		public function clear ( ) : void
		{
			title = null;
		}
		
		protected function hideText ( t : MovieClip ) : void
		{
			TweenMax.killTweensOf ( t );
			TweenMax.to ( t, 0.4, { y : height + 20, ease : Back.easeIn, onComplete : DisplayUtil.remove, onCompleteParams : [ t ] } );
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );
			
			addChild ( textHolder = new Sprite() );
			addChild ( masker = new Sprite() );
			
			var g : Graphics = masker.graphics;
				g.clear();
				g.beginFill ( 0x000000, 0.5 );
				g.drawRect ( 0, 0, 10, 10 );
				g.endFill();
				
			textHolder.mask = masker;
			
			invalidate();
		}
		
		override protected function invalidate ( ) : void
		{
			super.invalidate();
			
			if ( center && currentText )
			{
				currentText.x = width / 2 - currentText.width / 2;
			}
			
			if ( masker )
			{
				masker.width = width;
				masker.height = height;
			}
		}

	}
}