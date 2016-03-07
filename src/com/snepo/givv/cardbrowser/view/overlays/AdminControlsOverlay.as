package com.snepo.givv.cardbrowser.view.overlays
{
	/**
	* @author Andrew Wright
	*/

	import com.snepo.givv.cardbrowser.view.controls.*;
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.events.*;
	import com.snepo.givv.cardbrowser.model.*;
	import com.snepo.givv.cardbrowser.view.*;
	import com.snepo.givv.cardbrowser.util.*;

	import com.greensock.easing.*;
	import com.greensock.*;

	import flash.display.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.net.*;
	import flash.utils.*;
	import flash.system.*;

	public class AdminControlsOverlay extends Component implements IOverlay
	{
		public static const ADMIN_USERNAME :String = "admin";
		public static const ADMIN_PASSWORD :String = "489";
		public static const OPERATOR_USERNAME : String = "operator";
		public static const OPERATOR_PASSWORD : String = "164";

		protected var view : View;
		protected var timeoutTimer : Timer;
		protected var adminType : String;
		protected var upgradeRelease : String = "";
		protected var upgradeReleaseInfo : String = "";
		protected var downgradeRelease : String = "";
		protected var downgradeReleaseInfo : String = "";

		public function AdminControlsOverlay( type : String )
		{
			view = View.getInstance();
			timeoutTimer = new Timer(10000);
			timeoutTimer.addEventListener( TimerEvent.TIMER, onTimeout );
			adminType = type;

			super();
		}

		public function get canClose( ):Boolean
		{
			return true;
		}

		public function onRequestClose( ):void
		{

		}

		override protected function createUI( ):void
		{
			super.createUI( );

			timeoutTimer.reset();
			timeoutTimer.start();

			restartBtn.label = "Restart UI";
			restartBtn.addEventListener( MouseEvent.CLICK, restartUI );
			restartBtn.redraw();

			if (view.currentScreenKey == View.OOO_SCREEN)
			{
				if (!Model.getInstance().loaded)
					outOfOrderBtn.visible = false;
				else
				{
					outOfOrderBtn.label = "Disable Out Of Order";
					if (adminType == OPERATOR_USERNAME)
						outOfOrderBtn.enabled = false;
					else
						outOfOrderBtn.addEventListener( MouseEvent.CLICK, resetOutOfOrder );
				}
			}
			else
			{
				outOfOrderBtn.label = "Enable Out Of Order";
				outOfOrderBtn.addEventListener( MouseEvent.CLICK, setOutOfOrder );
			}
			outOfOrderBtn.redraw();

			if (adminType == ADMIN_USERNAME)
			{
				showLogsBtn.label = "View logs";
				showLogsBtn.addEventListener( MouseEvent.CLICK, showLogs );
				showLogsBtn.redraw();
			}
			else
			{
				showLogsBtn.visible = false;
			}

			if (adminType == ADMIN_USERNAME && Environment.RELEASE_DESCRIPTION != null)
			{
				var softwareBtn : Button = new Button;
				softwareBtn.x = showLogsBtn.x;
				softwareBtn.y = showLogsBtn.y + showLogsBtn.height + 20;
				softwareBtn.width = showLogsBtn.width;
				softwareBtn.height = showLogsBtn.height;

				softwareBtn.label = "Software Version";
				softwareBtn.addEventListener( MouseEvent.CLICK, showSoftwareVersion );
				softwareBtn.redraw();
				addChild(softwareBtn);

				// Load release version information
				var loader : URLLoader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, onUpgradeInfoLoaded, false, 0, true );
				loader.addEventListener ( IOErrorEvent.IO_ERROR, onInfoError, false, 0, true );
				loader.load ( new URLRequest ( Environment.RELEASE_PATH + "\\Upgrade\\release.txt" ) );
				loader = new URLLoader();
				loader.addEventListener ( Event.COMPLETE, onDowngradeInfoLoaded, false, 0, true );
				loader.addEventListener ( IOErrorEvent.IO_ERROR, onInfoError, false, 0, true );
				loader.load ( new URLRequest ( Environment.RELEASE_PATH + "\\Downgrade\\release.txt" ) );
			}

			exitAdminBtn.label = "Exit";
			exitAdminBtn.offFillColor = 0xBD0000; // red
			exitAdminBtn.addEventListener( MouseEvent.CLICK, exitAdmin );
			exitAdminBtn.redraw();

			controller.report ( 30, "Admin menu has been accessed" );
		}

		protected function dumpLogs( evt : MouseEvent ):void
		{
			Logger.dump();
		}

		protected function restartUI( evt : MouseEvent ):void
		{
			view.promptToRestart();
		}

		protected function setOutOfOrder( evt : MouseEvent):void
		{
			model.outOfOrder = true;
			view.currentScreenKey = View.OOO_SCREEN;
			view.modalOverlay.hide();
		}

		protected function resetOutOfOrder( evt : MouseEvent):void
		{
			model.outOfOrder = false;
			view.currentScreenKey = View.HOME_SCREEN;
			view.modalOverlay.hide();
			view.promptToRestart();
		}

		protected function showLogs( evt : MouseEvent ):void
		{
			Logger.show();
			view.modalOverlay.hide();
		}

		protected function showSoftwareVersion( evt : MouseEvent ):void
		{
			var action : String = 'none';
			var title : String = 'Software Version';
			var buttons : Array = ['OK'];
			if (upgradeRelease.length > 0 && upgradeRelease != Environment.RELEASE)
			{
				action = 'upgrade'
				title = 'Upgrade Software?';
				buttons = ['UPGRADE','CANCEL']
			}
			else if (downgradeRelease.length > 0 && downgradeRelease != Environment.RELEASE)
			{
				action = 'downgrade'
				title = 'Downgrade Software?';
				buttons = ['DOWNGRADE','CANCEL']
			}
			var alert : Alert = Alert.show ( { title : title,
				                                 message : (action != 'none' ? "\nCurrent Software Version\n" : "") +
				                                           "<font FACE='Courier'>" + Environment.RELEASE_DESCRIPTION + "</font>" +
				                                           (action == 'upgrade' ? "\nUpgrade Software Version\n<font FACE='Courier'>" + upgradeReleaseInfo + "</font>" : '') +
				                                           (action == 'downgrade' ? "\nDowngrade Software Version\n<font FACE='Courier'>" + downgradeReleaseInfo + "</font>" : ''),
				                                 useHtml : true,
				                                 autoDismiss : 30,
				                                 buttons : buttons } );
			alert.addEventListener ( AlertEvent.DISMISS, upgradeSoftware, false, 0, true );
			view.addChild(alert);
		}

		protected function upgradeSoftware( evt : AlertEvent )
		{
			if (evt.reason == "UPGRADE")
			{
				fscommand("exec", "Upgrade.cmd");
				fscommand("quit");
			}
			else if (evt.reason == "DOWNGRADE")
			{
				fscommand("exec", "Downgrade.cmd");
				fscommand("quit");
			}
			else
				exitAdmin(null);
		}

		protected function onUpgradeInfoLoaded ( evt : Event ) : void
		{
			upgradeRelease = evt.target.data.split(/\n/)[0];
			upgradeReleaseInfo = evt.target.data;
		}

		protected function onDowngradeInfoLoaded ( evt : Event ) : void
		{
			downgradeRelease = evt.target.data.split(/\n/)[0];
			downgradeReleaseInfo = evt.target.data;
		}

		protected function onInfoError ( evt : Event ) : void
		{
		}

		protected function exitAdmin( evt : MouseEvent ):void
		{
			view.modalOverlay.hide();
		}

		protected function onTimeout( evt : TimerEvent ):void
		{
			timeoutTimer.reset();
			view.modalOverlay.hide();
		}
	}
}