package
{
	import flash.events.Event;

	public class MoveMadeEvent extends Event
	{
		public var column;
		public var row;
		public var byMyself;
		
		public function MoveMadeEvent(type:String, col, row, byMyself, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.column = col;
			this.row = row;
			this.byMyself = byMyself;
			super(type, bubbles, cancelable);
		}
	}
}