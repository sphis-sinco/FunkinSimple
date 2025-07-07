package music;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	// Thank you ninjamuffin99
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var songPosition:Float = 0;
	public static var lastSongPos:Float;
	public static var songPosOffset:Float = 0;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new(bpm:Float = 100)
	{
		changeBPM(bpm);
	}

	public static function changeBPM(newBpm:Float)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}

    public static function mapBPMChanges(song:Song)
        {
            bpmChangeMap = [];

            // todo for if a song needs a bpm change
    
            var curBPM:Float = song.song.bpm;

            var event:BPMChangeEvent = {        
                stepTime: 0,
                songTime: 0,
                bpm: curBPM
            }
            
            bpmChangeMap.push(event);
        }
}