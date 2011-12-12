-- modified by Phil Napieralski

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(0)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"
tab4 = "\t\t\t\t"
tab5 = "\t\t\t\t\t"

xmlDir = as3.tolua(VALUE_XMLDir)
as3Dir = as3.tolua(VALUE_AS3Dir)
levelName = as3.tolua(VALUE_LevelName)
levelClassName = as3.tolua(VALUE_LevelClass)
exportOnlyXML = as3.tolua(VALUE_ExportOnlyXML)
playerInstanceName = as3.tolua(VALUE_PlayerInstance)

-- Output tilemap data
-- slow to call as3.tolua many times.

function exportMapCSV( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix,keywords)
    type = "tilemap"
    if string.find(layerFileName, "hit") or string.find(layerFileName, "collidable") then
        type="hitTilemap"
    end
    
    mapText = tab1.."<"..type.." scrollFactorX=\""..as3.tolua(mapLayer.xScroll).."\" scrollFactorY=\""..as3.tolua(mapLayer.yScroll).."\" name=\""..layerFileName.."\">\n<![CDATA[\n"..as3.tolua(DAME.ConvertMapToText(mapLayer,"","\n","",",",""))
        
    mapText = mapText.."]]>\n"..tab1.."</"..type..">\n"
        
	return mapText
end

-- This is the file for the map level class.
fileText = ""

maps = {}
spriteLayers = {}

masterLayerAddText = ""
stageAddText = tab3.."if ( addToStage )\n"
stageAddText = stageAddText..tab3.."{\n"

for groupIndex = 0,groupCount do
    triggerLayers = {}
    pathLayers = {}
    
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
    
	layerCount = as3.tolua(group.children.length) - 1
	
    layer = group.children[1]
    x = as3.tolua(layer.map.x)
	y = as3.tolua(layer.map.y)
	width = as3.tolua(layer.map.width)
	height = as3.tolua(layer.map.height)
    
	fileText = "<level boundsMinX=\""..x.."\" boundsMinY=\""..y.."\" boundsMaxX=\""..x+width.."\" boundsMaxY=\""..y+height.."\">\n"
	
	
	-- Go through each layer and store some tables for the different layer types.
	for layerIndex = 0,layerCount do
		layer = group.children[layerIndex]
		isMap = as3.tolua(layer.map)~=nil
		layerSimpleName = as3.tolua(layer.name)
		layerSimpleName = string.gsub(layerSimpleName, " ", "_")
		layerName = groupName..layerSimpleName
		if isMap == true then
			-- This needs to be done here so it maintains the layer visibility ordering.
			table.insert( maps, {layer,layerName} )
		elseif as3.tolua( layer.IsSpriteLayer() ) == true then
			table.insert( spriteLayers, {groupName,layer,layerName} )
			stageAddText = stageAddText..tab4.."addSpritesForLayer"..layerName.."(onAddSpritesCallback);\n"
        elseif as3.tolua(layer.IsShapeLayer()) == true and string.find(layerName, "trigger") then
            table.insert( triggerLayers, {groupName, layer, layerName} )
        elseif as3.tolua(layer.IsPathLayer()) == true then
            table.insert( pathLayers, {groupName, layer, layerName} )
		end
	end
end

for i,v in ipairs(maps) do
	fileText = fileText..exportMapCSV( maps[i][1], maps[i][2] )
end

-- generate a default properties string
propertiesString = "%%proploop%% %propname%=\"%propvalue%\"%%proploopend%%"

-- create the sprites.
fileText = fileText..tab1.."<objects>\n"
for i,v in ipairs(spriteLayers) do
	creationText = tab2.."<%class% x=\"%xpos%\" y=\"%ypos%\"/>\n" 

	fileText = fileText..as3.tolua(DAME.CreateTextForSprites(spriteLayers[i][2],creationText,"FlxExtendedSprite"))
end
fileText = fileText..tab1.."</objects>\n"


-- create the shapes / triggers
fileText = fileText..tab1.."<triggers>\n"
for i,v in ipairs(triggerLayers) do
    circleText = tab2.."<trigger type=\"circle\" x=\"%xpos%\" y=\"%ypos%\" radius=\"%radius%\""..propertiesString.." guid=\"%guid%\" />\n"
    rectangleText = tab2.."<trigger type=\"rectangle\" x=\"%xpos%\" y=\"%ypos%\" width=\"%width%\" height=\"%height%\""..propertiesString.." guid=\"%guid%\" />\n"
    fileText = fileText..as3.tolua(DAME.CreateTextForShapes(triggerLayers[i][2],circleText,rectangleText,"shape"))
end
fileText = fileText..tab1.."</triggers>\n"

fileText = fileText.."</level>\n"
	
-- Save the XML file!
DAME.WriteFile(xmlDir.."/"..levelName..".xml", fileText )




-- From http://stackoverflow.com/questions/1426954/split-string-in-lua
function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end


-- NOW CREATE THE LEVEL FILE
if exportOnlyXML == false then
    -- Get unique classes of sprites
    classText = "%class%," 
    classes = {}
    for i,v in ipairs(spriteLayers) do
        classText = as3.tolua(DAME.CreateTextForSprites(spriteLayers[i][2], classText,"FlxExtendedSprite"));
    end
    classes = split(classText, ",");
    
    -- for each unique sprite class, create an else if to handle it
    flags = {}
    createObjectsString = ""
    for i=1, #classes do
        if not flags[classes[i]] and classes[i] ~= "Player" then
            class = classes[i]
            
            createObjectsString = createObjectsString.." else if (element.name() == \""..class.."\") {\
                    var sprite:"..class.." = new "..class.."();\
                    for each( attr in element.attributes() ) {\
                        if( attr.name() == \"x\" ) sprite.x = parseInt(attr);\
                        if( attr.name() == \"y\" ) sprite.y = parseInt(attr);\
                    }\
                    sprites.add(sprite);\
                }"
            flags[classes[i]] = true
        end
    end

    fileText = "";
    fileText = "// Code originally generated with DAME. http://www.dambots.com \
// Heavily modified by Phil Napieralski / pnapieralski.com\
\
package\
{\
    import flash.events.Event;\
    import flash.net.URLLoader;\
    import flash.net.URLRequest;\
    import org.flixel.*;\
    import flash.utils.Dictionary;\
    import org.flixel.plugin.photonstorm.FlxExtendedSprite;\
    \
    public class Level extends FlxGroup\
    {\
        // This group contains all the tilemaps specified to use collisions.\
        public var hitTilemaps:FlxGroup = new FlxGroup;\
        \
        // This group contains all the tilemaps.\
        public var tilemaps:FlxGroup = new FlxGroup;\
        \
        public var triggers:FlxGroup = new FlxGroup;\
        \
        // This group contains all non-player sprites \
        //(player data will be put in "..playerInstanceName..") \
        public var sprites:FlxGroup = new FlxGroup;\
        \
        public static var boundsMinX:int;\
        public static var boundsMinY:int;\
        public static var boundsMaxX:int;\
        public static var boundsMaxY:int;\
        \
        public function Level( xmlFile:String ) { \
                var loader:URLLoader = new URLLoader();\
                \
                loader.addEventListener(Event.COMPLETE, loadXml);\
                loader.load(new URLRequest(xmlFile));\
                \
                add(tilemaps);\
                add(hitTilemaps);\
                \
                add(triggers);\
                add(sprites);\
                \
        }\
        \
        private function loadXml(e:Event):void {\
            var xml:XML = new XML(e.target.data);\
            \
            var levelAttr:XMLList = xml.attributes();\
            \
            for each( var attr:XML in levelAttr ) {\
                if( attr.name() == \"boundsMinX\" ) {\
                    boundsMinX = parseInt(attr);\
                } else if ( attr.name() == \"boundsMinY\" ) {\
                    boundsMinY = parseInt(attr);\
                } else if ( attr.name() == \"boundsMaxX\" ) {\
                    boundsMaxX = parseInt(attr);\
                } else if ( attr.name() == \"boundsMaxY\" ) {\
                    boundsMaxY = parseInt(attr);\
                }\
            }\
            FlxG.camera.setBounds(boundsMinX, boundsMinY, boundsMaxX, boundsMaxY);\
            // For collision detection\
            FlxG.worldBounds.x = boundsMinX;\
			FlxG.worldBounds.y = boundsMinY;\
			FlxG.worldBounds.width = boundsMaxX - boundsMinX;\
			FlxG.worldBounds.height = boundsMaxY - boundsMinY;\
            parseTilemaps(xml);\
            parseObjects(xml);\
            parseTriggers(xml);\
        }\
        \
        private function parseTilemaps(xml:XML):void {\
            // Parse out tilemaps\
            var tilemapList:XMLList = xml.tilemap;\
            var tilemap:FlxTilemap;\
            \
            for each( var tilemapElement:XML in tilemapList ) {\
                tilemap = new FlxTilemap();\
                \
                tilemap.loadMap(tilemapElement, Assets.tileset, 16, 16);\
                \
                tilemaps.add(tilemap);\
                \
                for each( var tilemapAttr:XML in tilemapElement.attributes() ) {\
                    if( tilemapAttr.name() == \"scrollFactorX\" ) \
                        tilemap.scrollFactor.x = parseFloat(tilemapAttr);\
                    else if( tilemapAttr.name() == \"scrollFactorY\" )\
                        tilemap.scrollFactor.y = parseFloat(tilemapAttr);\
                }\
            }\
            \
            // Parse out collidable tilemaps (hitTilemap)\
            tilemapList = xml.hitTilemap;\
            \
            for each( tilemapElement in tilemapList ) {\
                tilemap = new FlxTilemap();\
                \
                tilemap.loadMap(tilemapElement, Assets.tileset, 16, 16);\
                \
                for each( tilemapAttr in tilemapElement.attributes() ) {\
                    if( tilemapAttr.name() == \"scrollFactorX\" ) \
                        tilemap.scrollFactor.x = parseFloat(tilemapAttr);\
                    else if( tilemapAttr.name() == \"scrollFactorY\" )\
                        tilemap.scrollFactor.y = parseFloat(tilemapAttr);\
                }\
                hitTilemaps.add(tilemap);\
            }\
        }\
        \
        private function parseObjects(xml:XML):void {\
            for each( var element:XML in xml.objects.children() ) {\
                // Setup player\
                if ( element.name() == \"Player\" ) {\
                    for each( var attr:XML in element.attributes() ) {\
						if ( attr.name() == \"x\" || attr.name() == \"X\" ) {\
							"..playerInstanceName..".x = parseInt(attr);\
						} else if ( attr.name() == \"y\" || attr.name() == \"Y\" ) {\
							"..playerInstanceName..".y = parseInt(attr);\
						}\
                    }\
                }  "..createObjectsString.."\
            }\
        }\
        \
        private function parseTriggers(xml:XML):void {\
            trace(xml.triggers);\
        }\
\
        override public function destroy():void\
        {\
            super.destroy();\
            \
            tilemaps = null;\
            hitTilemaps = null;\
            triggers = null;\
        }\
\
    }\
}";
    
    DAME.WriteFile(as3Dir.."/"..levelClassName..".as", fileText )
end

return 1
