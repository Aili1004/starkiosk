package com.snepo.givv.cardbrowser.view.overlays
{
	/**
	 * @author andrewwright
	 */

	public interface IOverlay
	{
		function get canClose ( ) : Boolean;
		//function get isSuperModal ( ) : Boolean;
		function onRequestClose ( ) : void;
	}
}