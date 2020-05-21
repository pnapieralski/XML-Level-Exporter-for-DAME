XML/Level exporter for DAME
===========================

Using
-----
1. Place this script in your DAME/lua/Exporters directory
2. When creating your map, all layers that the player will collide with should have "collidable" or "hit" in the name. Eg; "hitCastle" to prevent the player from walking through them.
3. Triggers should be placed in a shape layer named "triggers"

Output of export script
------------------------
1. An XML file will always be output, this is all the level data you will need to get started (see below for an example .xml file).
2. A Level.as file will also be created in the AS3 directory you specify. 
3. When exporting, you must also specify where your player class is located. Mine defaults to a static class called "Registry" which contains the static class "Player" that I initialize before loading the level.


To load the level
-----------------
As an example, here is my playState:

<as>

	public class PlayState extends FlxState {
		override public function create():void {
			super.create();
			
            // Initialize the player class
			Registry.init();
            
            // Add the player to our state
			add(Registry.player);
			
			var level1:Level = new Level("data/level1.xml");
			add(level1);
			
		}
	}
    
</as>


DAME
----
Find DAME here (Created by Charles Goatley)
