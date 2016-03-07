package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;

	public class ErrorManager extends EventDispatcher
	{
		public static const UNKNOWN_ERROR : Object = { code : -1, title : "Error", message : "Unknown error.", buttons : [ "OK" ] };

		protected static var instance : ErrorManager;
		protected static var stage : Stage;

		protected var _errors : Array = [];
		protected var _errorsByCode : Dictionary = new Dictionary();

		public static function init ( stageReference : Stage ) : ErrorManager
		{
			stage = stageReference;
			instance = new ErrorManager();

			return instance;
		}

		public static function getInstance ( ) : ErrorManager
		{
			if ( instance == null )
			{
				throw new Error ( "ErrorManager not initialized. Call ErrorManager.init ( stage );" );
			}

			return instance;
		}

		public function load ( path : String ) : void
		{
			var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, onErrorsLoaded );
				loader.load ( new URLRequest ( path ) );
		}

		public static function getErrorByCode ( code : String, propertyMap : Object = null ) : Object
		{
			return getInstance().getErrorByCode ( code, propertyMap );
		}

		public function getErrorByCode ( code : String, propertyMap : Object = null ) : Object
		{
			var errorCode : String;

			// Crack error code from Flash errors
			if (code.substr(0,7) == "Error #")
				errorCode = code.substr(7,4);
			else
				errorCode = code;

			if ( hasError ( errorCode ) )
			{
				var error : Object = ObjectUtil.clone ( _errorsByCode [ errorCode ] );
				var level : int = 50;
				if (error.level == 'fatal')
					level = 100;
				else if (error.level == 'error')
					level = 50;
				else if (error.level == 'warning')
					level = 10;
				if ( propertyMap )
				{
					for ( var i : String in propertyMap )
					{
						var props : Object = propertyMap[i];
						try
						{
							error[i] = StringUtil.replaceKeys ( error[i], propertyMap[i] );
						}catch ( e : Error )
						{

						}
					}
				}
				Logger.log("Error = " + error.code + ", " + error.title + ", " + error.message, Logger.ERROR);
				Controller.getInstance().report ( level, "Error = " + error.code + ", " + error.title + ", " + error.message);
				return error;
			}

			// Handle unknown error
			Logger.log("Unknown Error = " + code, Logger.ERROR);
			Controller.getInstance().report (50, "Unknown Error = " + code);
			var unknownError : Object = new Object;
			unknownError.code = "-1"
			unknownError.title = "Unknow Error"
			unknownError.message = code
			unknownError.buttons = [ "OK" ];

			return unknownError
		}

		public function hasError ( code : String ) : Boolean
		{
			return _errorsByCode [ code ] != null;
		}

		public function throwError ( codeOrError : * ) : void
		{
			var error : Object = codeOrError is String ? getErrorByCode ( codeOrError as String ) : codeOrError as Object;
			if ( error == null ) error = UNKNOWN_ERROR;
		}

		protected function onErrorsLoaded ( evt : Event ) : void
		{
			var source : XML = new XML ( evt.target.data );
			var errorList : XMLList = source..error;

			for ( var i : int = 0; i < errorList.length(); i++ )
			{
				var errorData : XML = errorList[i];

				var error : Object = {};
				var code : String = errorData.code.text();
				var level : String = errorData.level.text();
				var description : String = errorData.description.text();
				var title : String = errorData.title.text();
				var message : String = errorData.message.text();

				var clientHandlingData : XML = errorData.clienthandling[0];

				if ( clientHandlingData )
				{
					var clientHandling : Object = {};

					var silent : Boolean = clientHandlingData.silent.text() == "true";
					var timeout : int = int(clientHandlingData.timeout.text() );

					var buttonsList : XMLList = clientHandlingData.buttons[0].children();

					var actions : Object = {};
					var buttons : Array = [];

					for ( var j : int = 0; j < buttonsList.length(); j++ )
					{
						var buttonLabel : String = buttonsList[j].@label;
						var buttonAction : String = buttonsList[j].@action;
						var buttonData : String = buttonsList[j].@data;

						buttons.push( { label : buttonLabel, action : buttonAction, data : buttonData } )
					}

					clientHandling.silent = silent;
					clientHandling.buttons = buttons;
					clientHandling.timeout = timeout;
				}

				// This is so the alert knows how to treat the buttons
				// Kinda hacky, but it'll do for now.
				error.isError = true;
				error.code = code;
				error.level = level;
				error.description = description;
				error.title = title;
				error.message = message;
				error.autoDismissTime = timeout || 0;
				error.buttons = buttons;
				error.handling = clientHandling;

				_errorsByCode [ code ] = error;
			}

			dispatchEvent ( new Event ( Event.COMPLETE ) );
		}

		public function ErrorManager ( ) : void
		{
			super ( this );
		}
	}

}