package com.snepo.givv.cardbrowser.view.controls
{
	import com.snepo.givv.cardbrowser.view.core.*;
	import com.snepo.givv.cardbrowser.util.*;

	import flash.geom.*;

	public class MessageSpinner extends Component
	{
		public function MessageSpinner ()
		{
			// Invert colour for Linx
			if (Environment.isLinx)
			{
				spinner.transform.colorTransform = new ColorTransform(-1,-1,-1,1,255,255,255,0);
			}
		}
	}
}