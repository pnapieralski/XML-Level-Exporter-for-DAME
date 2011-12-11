-- Display the settings for the exporter.
DAME.AddHtmlTextLabel("Phil's custom xml exporter. If you are using this, you are probably Phil.")

DAME.AddBrowsePath("Xml dir:","XMLDir",false, "Where you place the xml files.")

DAME.AddBrowsePath("AS3 dir:","AS3Dir",false, "Where you place the Actionscript file (Level.as).")

DAME.AddTextInput("Level Name", "", "LevelName", true, "The name you wish to call this level." )

DAME.AddTextInput("Level Class", "Level", "LevelClass", true, "What to call the class that loads the XML files." )

DAME.AddTextInput("Player Instance Name", "Registry.player", "PlayerInstance", true, "When player sprite is parsed, what sprite should be updated (in as3 code)?")

DAME.AddCheckbox("Export only XML","ExportOnlyXML",false,"If ticked then the script will only export the map XML files and nothing else.")

return 1
