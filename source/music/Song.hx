package music;

typedef Song =
{
	var song:
		{
			var notes:Array<Section>;
			var ?voiceList:Array<String>;
			var needsVoices:Bool;
			var song:String;
			var bpm:Float;
			var speed:Float;
		};
	var ?version:String;
	var ?generatedBy:String;
}

typedef Section =
{
	var sectionNotes:Array<Array<Float>>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
}
