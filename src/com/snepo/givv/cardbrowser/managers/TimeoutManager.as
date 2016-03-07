package com.snepo.givv.cardbrowser.managers
{
	import com.snepo.givv.cardbrowser.view.screens.*;
	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.control.*;
	import com.snepo.givv.cardbrowser.errors.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;
	import com.snepo.givv.cardbrowser.*;

	import flash.events.*;
	import flash.utils.*;
	import flash.ui.*;

	public class TimeoutManager extends EventDispatcher
	{
		protected static var instance : TimeoutManager;
		protected static var restartTime : Date;

		public static function getInstance ( ) : TimeoutManager
		{
			instance ||= new TimeoutManager ( new Private() );
			return instance;
		}

		protected var runner : Timer;
		protected var locked : Boolean = false;

		public function TimeoutManager ( p : Private )
		{
			super ( this );
			if ( p == null ) throw new SingletonError ( "TimeoutManager" );
			// set restart time to tomorrrow between 00:00 and 03:00
			restartTime = new Date();
			restartTime.date += 1;
			restartTime.hours = 0;
			restartTime.minutes = Math.random() * 180; // 3 hour window
			Logger.log("Kiosk restart time set to " + restartTime.toLocaleString(), Logger.LOG);
		}

		public static function lock ( ) : void
		{
			getInstance().lock();
		}

		public static function unlock ( ) : void
		{
			getInstance().unlock();
		}

		public static function get locked ( ) : Boolean
		{
			return getInstance().locked;
		}

		public function lock ( ) : void
		{
			locked = true;
			Main.instance.timeoutLocked.visible = true;
			reset();
		}

		public function unlock ( ) : void
		{
			locked = false;

			Main.instance.timeoutLocked.visible = false;
		}

		public function start ( time : int ) : void
		{
			if (!Environment.DEBUG)
			{
				Mouse.hide();
			}

			if ( runner )
			{
				runner.stop();
				runner.removeEventListener ( TimerEvent.TIMER, handlePanelTimeout );
				runner = null;
			}
			if ( time > 0 )
			{
				runner = new Timer( time * 1000 );
				runner.addEventListener ( TimerEvent.TIMER, handlePanelTimeout, false, 0, true );
				runner.start();
			}
		}

		public function reset ( ) : void
		{
			if ( runner )
			{
				runner.reset();
				runner.start();
			}

		}

		protected function handlePanelTimeout ( evt : TimerEvent ) : void
		{
			if ( locked ) return;

			var view : View = View.getInstance();
			var model : Model = Model.getInstance();
			var controller : Controller = Controller.getInstance();

			if ( view.currentScreenKey == View.PRINTING_SCREEN )
			{
				var printingScreen : PrintingScreen = view.getScreen ( View.PRINTING_SCREEN ) as PrintingScreen;
				if ( printingScreen.printHasComplete )
				{
					view.modalOverlay.forceClose();
					controller.reset();
				}
				return;
			}

			if ( !(view.currentScreen is HomeScreen) )
				view.promptToRestoreSession();
			else
			{
				if (!Environment.DEBUG)
					Mouse.hide();

				//controller.reset(); -- I don't think this is needed

				var now : Date = new Date()
				if (now.time > restartTime.time ||
						model.host.remoteControl == HostModel.REMOTE_CONTROL_RESTART_UI ||
						model.host.remoteControl == HostModel.REMOTE_CONTROL_UPGRADE_NOW ||
						model.host.remoteControl == HostModel.REMOTE_CONTROL_DOWNGRADE_NOW)
					view.promptToRestart();
			}

			return;
		}
	}
}

class Private{}
