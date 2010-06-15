package
{
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	public interface IConnection extends IEventDispatcher
	{	
		function sendMessage(m:Object):void
		function receive(m:Object):void
		function set Game(g):void

		function setupConnectionForJoining():void
		function setupIncomingStream(id:String):void;
		function netStreamHandler(e:NetStatusEvent):void
		function setupConnection():void
		function netConnectionHandler(e:NetStatusEvent):void
		function setupOutgoingStream(joining:Boolean = false):void
	}
}