package com.snepo.givv.cardbrowser.view.core
{
	import com.snepo.givv.cardbrowser.view.core.gesture.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;

	public class Component extends MovieClip
	{

		protected var _width : Number = 1;
		protected var _height : Number = 1;

		protected var _data : Object = {};
		protected var _enabled : Boolean = true;
		protected var _canShow : Boolean = true;

		protected var _gestures : Dictionary = new Dictionary();

		public var model : Model;
		public var controller : Controller;

		public function Component()
		{
			super();

			model = Model.getInstance();
			controller = Controller.getInstance();

			_width = super.width;
			_height = super.height;

			scaleX = scaleY = 1;

			createUI ( );

			if ( stage )
			{
				initStageEvents();
			}else
			{
				addEventListener ( Event.ADDED_TO_STAGE, initStageEvents );
			}

			invalidate();

		}

		protected function initStageEvents ( evt : Event = null ) : void
		{
			removeEventListener ( Event.ADDED_TO_STAGE, initStageEvents );
			addEventListener ( Event.REMOVED_FROM_STAGE, returnFocusToStage, false, 0, true );
		}

		protected function returnFocusToStage ( evt : Event ) : void
		{
			removeEventListener ( Event.REMOVED_FROM_STAGE, returnFocusToStage )
			if ( stage ) stage.focus = stage;
		}

		protected function createUI ( ) : void
		{

		}

		public function addGesture ( gesture : Gesture ) : void
		{
			if ( !_gestures [ gesture.type ] ) _gestures [ gesture.type ] = gesture;
		}

		public function removeGesture ( type : String ) : void
		{
			if ( _gestures [ type ] )
			{
				_gestures [ type ].destroy();
				delete _gestures [ type ];
			}
		}

		public function hasGesture ( type : String ) : Boolean
		{
			return _gestures [ type ] != null;
		}

		public function get gestureList ( ) : String
		{
			var list : Array = []

			for each ( var g : Gesture in _gestures )
			{
				list.push ( g.type );
			}

			return list.join ( ", " );
		}

		public function removeAllGestures ( ) : void
		{
			for each ( var g : Gesture in _gestures )
			{
				g.destroy();
				g = null;
			}

			_gestures = new Dictionary();
		}

		override public function set width ( w : Number ) : void
		{
			_width = w;
			invalidate();
		}

		override public function get width ( ) : Number
		{
			return _width;
		}

		override public function set height ( h : Number ) : void
		{
			_height = h;
			invalidate();
		}

		override public function get height ( ) : Number
		{
			return _height;
		}

		public function get nativeWidth ( ) : Number
		{
			return super.width;
		}

		public function get nativeHeight ( ) : Number
		{
			return super.height;
		}

		public function setSize ( w : Number, h : Number ) : void
		{
			this._width = w;
			this._height = h;

			this.invalidate();
		}

		public function getSize ( ) : Object
		{
			return { width : width, height : height };
		}

		public function move ( x : Number, y : Number ) : void
		{
			this.x = x;
			this.y = y;
		}

		override public function set enabled ( e : Boolean ) : void
		{
			this._enabled = e;
			this.applyEnabled();
		}

		override public function get enabled ( ) : Boolean
		{
			return this._enabled;
		}

		public function nativeAddChild ( i : DisplayObject ) : DisplayObject
		{
			return super.addChild ( i );
		}

		public function nativeRemoveChild ( i : DisplayObject ) : DisplayObject
		{
			return super.removeChild ( i );
		}

		protected function applyEnabled ( ) : void
		{

		}

		public function dispose ( ) : void
		{

		}

		public function destroy ( ) : void
		{
			DisplayUtil.remove ( this );
		}

		public function set data ( d : Object ) : void
		{
			this._data = d;
			this.render();
		}

		public function get data ( ) : Object
		{
			return this._data;
		}

		protected function render ( ) : void
		{

		}

		public function redraw ( ) : void
		{
			invalidate();
		}

		protected function invalidate ( ) : void
		{

		}

		public function get canShow ( ) : Boolean
		{
			return _canShow;
		}

	}
}