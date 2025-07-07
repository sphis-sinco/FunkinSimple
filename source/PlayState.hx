package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import haxe.Json;
import music.Conductor;
import music.MusicState;
import music.Song;
import openfl.Assets;

class PlayState extends MusicState
{
	public static var SONG_JSON:Song;

	public var startedSong:Bool = false;
	public var endedSong:Bool = false;

	public var songPos:FlxText;

	public static var strumlineY:Float = 50;

	var Inst:FlxSound;
	var VoicesGrp:Array<FlxSound>;

	override public function new(song:String = 'test')
	{
		// set song json
		try
		{
			SONG_JSON = Json.parse(Assets.getText('assets/gameplay/songs/$song/$song.json'));
		}
		catch (e)
		{
			song = 'test';
			FlxG.switchState(() -> new PlayState(song));
		}

		// base stuff to get conductor workin
		Conductor.mapBPMChanges(SONG_JSON);
		Conductor.changeBPM(SONG_JSON.song.bpm);

		Inst = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Inst.ogg');
		Inst.onComplete = endSong;
		Inst.pause();

		if (SONG_JSON.song.needsVoices)
		{
			if (SONG_JSON.song.voiceList == null)
			{
				var Voice = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Voices.ogg');
				Voice.pause();
				VoicesGrp.push(Voice);
			}
			else
			{
				for (voice in SONG_JSON.song.voiceList)
				{
					var Voice = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Voices-$voice.ogg');
					Voice.pause();
					VoicesGrp.push(Voice);
				}
			}

			trace('${VoicesGrp.length} voice "channels"');
		}

		Conductor.songPosition = 0;

		songPos = new FlxText(0, 0, 0, "Hello", 16);

		super();
	}

	override public function create()
	{
		add(songPos);

		// note adding
		/*
			for (note in SONG_JSON.notes)
			{
				var newNote:NoteSpr = new NoteSpr(note.noteId, note.noteTime);
				newNote.missCallback = noteMiss;
				noteGrp.add(newNote);
			}
			add(noteGrp);
		 */

		super.create();
	}

	public function noteMiss() {}

	override public function update(elapsed:Float)
	{
		// only move the songPosition if the song hasn't ended
		if (!endedSong)
			Conductor.songPosition += elapsed * 1000;

		if (Conductor.songPosition >= 0 && !startedSong)
		{
			startedSong = true;
			Inst.resume();
			for (voice in VoicesGrp)
			{
				voice.resume();
			}
		}

		// Song Position Info
		var musicLen:Float = FlxG.sound.music.length / 1000; // divide by 1000 cause its in miliseconds
		var timeLeft:Float = FlxMath.roundDecimal(musicLen - Conductor.songPosition / 1000, 0);

		// this is for the countdown (when I add it)
		if (timeLeft > musicLen)
			timeLeft = musicLen; // countdown time doesnt add to the length

		var songText:String = '' + timeLeft;
		songPos.text = "Song Pos: " + songText;

		super.update(elapsed);
	}

	public function endSong()
	{
		endedSong = true;
		// FlxG.switchState(new ResultsState(SONG_STATS));
	}
}
