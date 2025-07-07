package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
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
	var VoicesGrp:Array<FlxSound> = [];

	var cpuControlled = false;

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

		Inst = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Inst.wav');
		Inst.onComplete = endSong;
		Inst.pause();

		if (SONG_JSON.song.needsVoices)
		{
			if (SONG_JSON.song.voiceList == null)
			{
				var Voice = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Voices.wav');
				Voice.pause();
				VoicesGrp.push(Voice);
			}
			else
			{
				for (voice in SONG_JSON.song.voiceList)
				{
					var Voice = new FlxSound().loadEmbedded('assets/gameplay/songs/$song/Voices-$voice.wav');
					Voice.pause();
					VoicesGrp.push(Voice);
				}
			}

			trace('${VoicesGrp.length} voice "channels"');
		}

		Conductor.songPosition = 0;
		// Conductor.songPosition -= Conductor.crochet * 5;

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

		FlxG.signals.focusLost.add(() ->
		{
			if (Inst.playing)
			{
				Inst.pause();
				for (voice in VoicesGrp)
				{
					voice.pause();
				}
			}
		});
		FlxG.signals.focusGained.add(() ->
		{
			if (Conductor.songPosition >= 0)
			{
				Inst.play();
				for (voice in VoicesGrp)
				{
					voice.play();
				}
			}
		});

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		generateStaticArrows(0);
		generateStaticArrows(1);

		generateSong();

		super.create();
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<Section>;

		// NEW SHIT
		noteData = SONG_JSON.song.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else {}
			}
			daBeats += 1;
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		var path:String = 'assets/gameplay/ui/NOTE_assets';

		for (i in 0...4)
		{
			FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var arrTex = FlxAtlasFrames.fromSparrow('$path.png', '$path.xml');
			babyArrow.frames = arrTex;
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.scrollFactor.set();
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();
			babyArrow.antialiasing = true;

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i + 1;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}

			switch (Math.abs(i + 1))
			{
				case 1:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 4:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	override public function update(elapsed:Float)
	{
		// only move the songPosition if the song hasn't ended
		if (!endedSong)
			Conductor.songPosition += elapsed * 1000;

		if (Conductor.songPosition >= 0 && !startedSong)
		{
			startedSong = true;
			Inst.play(true);
			for (voice in VoicesGrp)
			{
				voice.play(true);
			}
		}

		// Song Position Info
		var musicLen:Float = Inst.length / 1000; // divide by 1000 cause its in miliseconds
		var timeLeft:Float = FlxMath.roundDecimal(musicLen - Conductor.songPosition / 1000, 0);

		// this is for the countdown (when I add it)
		if (timeLeft > musicLen)
			timeLeft = musicLen; // countdown time doesnt add to the length

		var songText:String = '' + timeLeft;
		songPos.text = "Song Pos: " + songText;

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (startedSong)
		{
			if (notes != null)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					noteScript(daNote);
				});
			}

			if (notes.length > 0)
			{
				if (startedSong)
				{
					var i:Int = 0;
					while (i < notes.length)
					{
						var daNote:Note = notes.members[i];
						if (daNote == null)
							continue;
						if (daNote.mustPress)
						{
							if (daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
								goodNoteHit(daNote);
						}

						// Kill extremely late notes and cause misses
						if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
						{
							if (daNote.mustPress && !cpuControlled && !endedSong && (daNote.tooLate || !daNote.wasGoodHit))
								noteMiss(daNote);

							daNote.active = daNote.visible = false;
							invalidateNote(daNote);
						}
						if (daNote.exists)
							i++;
					}
				}
				else
				{
					notes.forEachAlive(function(daNote:Note)
					{
						daNote.canBeHit = false;
						daNote.wasGoodHit = false;
					});
				}
			}
		}

		super.update(elapsed);
	}

	public var noteKillOffset:Float = 350;

	public function noteScript(daNote:Note)
	{
		if (daNote.y > FlxG.height)
		{
			daNote.active = false;
			daNote.visible = false;
		}
		else
		{
			daNote.visible = true;
			daNote.active = true;
		}

		daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG_JSON.song.speed, 2)));

		// i am so fucking sorry for this if condition
		if (daNote.isSustainNote
			&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
			&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
		{
			var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
			swagRect.y /= daNote.scale.y;
			swagRect.height -= swagRect.y;

			daNote.clipRect = swagRect;
		}

		if (!daNote.mustPress && daNote.wasGoodHit)
		{
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		// WIP interpolation shit? Need to fix the pause issue
		// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

		if (daNote.y < -daNote.height)
		{
			if (daNote.isSustainNote && daNote.wasGoodHit)
			{
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			else
			{
				if (daNote.tooLate || !daNote.wasGoodHit)
				{
					// health -= 0.0475;
				}

				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		}
	}

	public function endSong()
	{
		endedSong = true;
		// FlxG.switchState(new ResultsState(SONG_STATS));
	}
	public function goodNoteHit(note:Note):Void
	{
	}

	public function invalidateNote(note:Note):Void
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function noteMiss(daNote:Note):Void
	{
		// You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		// if (ClientPrefs.data.ghostTapping)
		//	return; // fuck it

		noteMissCommon(direction);
		// FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score shit
	}
}
