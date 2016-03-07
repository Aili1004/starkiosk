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
	
	public class Stepper extends Component
	{
		protected var _labelFunction : Function;
		protected var _minimum : Number = 1;
		protected var _maximum : Number = 10;
		protected var _value : Number = _minimum;
		
		public var increment : Number = 1;
		
		public function Stepper()
		{
			super();
		}
		
		override protected function createUI ( ) : void
		{
			super.createUI ( );
			
			FontUtil.applyTextFormat ( valueBtn.labelField, { size : 30 } );
			
			downBtn.label = "-";
			downBtn.addEventListener ( ButtonEvent.REPEAT, tickValue );
			downBtn.selected = false;
			downBtn.selectable = false;
			downBtn.repeating = true;
			downBtn.onLabelColor = 0xFFFFFF;
			downBtn.offLabelColor = 0xFFFFFF;
			downBtn.applySelection();
			
			upBtn.label = "+";
			upBtn.addEventListener ( ButtonEvent.REPEAT, tickValue );
			upBtn.selected = false;
			upBtn.selectable = false;
			upBtn.repeating = true;
			upBtn.onLabelColor = 0xFFFFFF;
			upBtn.offLabelColor = 0xFFFFFF;
			upBtn.applySelection();
			
			valueBtn.mouseEnabled = false;
			valueBtn.offFillColor = 0x169CD4; // light blue
			valueBtn.onLabelColor = 0xFFFFFF;
			valueBtn.offLabelColor = 0xFFFFFF;
			valueBtn.applySelection();

			value = value;
			
		}
		
		protected function tickValue ( evt : ButtonEvent ) : void
		{
			var delta : Number = evt.target == downBtn ? -increment : increment;
			value += delta;
		}
		
		public function set minimum ( m : Number ) : void
		{
			this._minimum = m;
			value = value;
		}
		
		public function get minimum ( ) : Number
		{
			return this._minimum;
		}
		
		public function set maximum ( m : Number ) : void
		{
			this._maximum = m;
			value = value;
		}
		
		public function get maximum ( ) : Number
		{
			return this._maximum;
		}
		
		public function set labelFunction ( f : Function ) : void
		{
			_labelFunction = f;
			value = value;
		}
		
		public function get labelFunction ( ) : Function
		{
			return _labelFunction;
		}
		
		public function set value ( v : Number ) : void
		{
			if ( v < minimum ) v = minimum;
			if ( v > maximum ) v = maximum;
			
			var changed : Boolean = v != value;
			
			this._value = v;
			this.renderValue();
			
			if ( changed ) dispatchEvent ( new Event ( Event.CHANGE ) );
		}
		
		public function get value ( ) : Number
		{
			return this._value;
		}
		
		protected function renderValue ( ) : void
		{
			var stringValue : String = value + "";
			if ( labelFunction != null ) stringValue = labelFunction ( stringValue );
			
			valueBtn.label = stringValue;
			valueBtn.redraw();
		}
		
		override protected function invalidate ( ) : void
		{
			downBtn.height = height;
			downBtn.width = 70;
			
			upBtn.height = height;
			upBtn.width = 70;
			upBtn.x = width - upBtn.width;
			
			valueBtn.x = downBtn.x + downBtn.width + 5;
			valueBtn.height = height;
			valueBtn.width = ( upBtn.x - 5 ) - valueBtn.x;

		}
		

	}
}