/*******************
Hello Bela!
Connect your headphones to the stereo audio output of the Bela and run this program.

(c) 2017: Jonathan Reus, Marije Baalman, Giulio Moro, Andrew McPherson
*/

s = Server.default;

// Set up options for the Bela
s.options.numAnalogInChannels = 2;
s.options.numAnalogOutChannels = 2;
s.options.numDigitalChannels = 0;
s.options.maxLogins = 4;
s.options.bindAddress = "0.0.0.0"; // allow anyone on the network connect to this server

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

/**
 *  Config
 **/
~soundDir = "/root/Bela/projects/dephone-sounds";
//~soundDir = "/Users/colin/Projects/dephone/sound";

SerialPort.devices().postln();
~portName = "/dev/ttyACM0";
//~portName = "/dev/cu.usbmodem11201";

~experienceSoundsByPhase = [
    [
        "1-idle-01.wav",
        "1-idle-02.wav",
        "1-idle-03.wav",
        "1-idle-04.wav",
        "1-idle-05.wav",
    ],
    [
        "2-powerup-01.wav",
        "2-powerup-02.wav",
    ],
    [
        "3-countdown-01.wav",
        "3-countdown-02.wav",
        "3-countdown-03.wav",
        "3-countdown-04.wav",
    ],
];

~voiceSounds = [
    "voices-rendered-01 [2024-02-23 200945].aif",
    "voices-rendered-02 [2024-02-23 200945].aif",
    "voices-rendered-03 [2024-02-23 200945].aif",
    "voices-rendered-04 [2024-02-23 200945].aif",
    "voices-rendered-05 [2024-02-23 200945].aif",
    "voices-rendered-06 [2024-02-23 200944].aif",
    "voices-rendered-07 [2024-02-23 200945].aif",
];


s.waitForBoot {
	var buffer = "";
    var bpm = 160;
    var secondsPerBeat = 60 / bpm;
    var beatsPerBar = 4;
    var barDuration = beatsPerBar * secondsPerBeat;

	TempoClock.default.tempo = bpm/60;

	/**
	* Tracks phase of experience
	**/
	// 0. approach, scans QR, getting instructions, place phone down
	// 1. holding buttons
	// 2. door opens, person is dephoned, countdown
	~experiencePhase = 0;

    /**
     *  Set up synths
     **/
    SynthDef("stream-buf", {
        arg out = 0, bufnum, shouldLoop = 0, amp = 1.0;

        Out.ar(
            out,
            DiskIn.ar(2, bufnum, loop: shouldLoop)
        ) * amp;
    }).add;

    /**
     *  Sets up state machine
     **/
    ~handlePhaseAdvanced = {
		~experiencePhase.postln();
        if(~experiencePhase == 0, {
			if (~musicPlayer.isNil == false, {
				~musicPlayer.free;
			});
			~musicBuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~experienceSoundsByPhase[~experiencePhase].choose(), 0, 2);
            ~musicPlayer = Synth.new("stream-buf", [\bufnum, ~musicBuf, \shouldLoop, 1, \amp, -4.dbamp()], s);
        });

        if(~experiencePhase == 1, {
			if (~transitionPlayer.isNil == false, {
				~transitionPlayer.free;
			});
			if(~musicPlayer.isNil == false, {
				~musicPlayer.free
			});
			~transitionBuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~experienceSoundsByPhase[~experiencePhase].choose(), 0, 2);
            ~transitionPlayer = Synth.new("stream-buf", [\bufnum, ~transitionBuf, \shouldLoop, 0], s);

            // Automatically advance in 7 bars
			TempoClock.default.sched(7 * beatsPerBar, {
				~advancePhaseState.value();
			});
        });

        if(~experiencePhase == 2, {
            if (~musicPlayer.isNil == false, {
                ~musicPlayer.free;
            });
			~musicBuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~experienceSoundsByPhase[~experiencePhase].choose(), 0, 2);
			~musicPlayer = Synth.new("stream-buf", [\bufnum, ~musicBuf, \amp, -4.0.dbamp()], s);

            TempoClock.default.sched((beatsPerBar * 8).rand(beatsPerBar * 12), {
                ~voiceBuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~voiceSounds.choose(), 0, 2);
                ~voicePlayer = Synth.new("stream-buf", [\bufnum, ~voiceBuf, \shouldLoop, 0, \amp, -3.0.dbamp()], s);
            });
            TempoClock.default.sched((beatsPerBar * 28).rand(beatsPerBar * 36), {
                ~voice2Buf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~voiceSounds.choose(), 0, 2);
                ~voice2Player = Synth.new("stream-buf", [\bufnum, ~voice2Buf, \shouldLoop, 0, -3.0.dbamp()], s);
            });



			// schedule transition to next phase in 41 bars
			TempoClock.default.sched(41 * beatsPerBar, {
				~advancePhaseState.value();
			});

        });
    };
    ~advancePhaseState = {
        ~experiencePhase = (~experiencePhase + 1) % 3;
		~experiencePhase.postln();
		~handlePhaseAdvanced.value();
    };

    /**
     *  handles phase advanced the first time
     **/
    ~handlePhaseAdvanced.value();

    /**
     *  Intializes arduino serial connection
     **/
    ~arduino = SerialPort(~portName, 9600, crtscts: true);

    /**
     *  Read arduino
     **/
    ~processData = {
        arg data;

        buffer = buffer ++ data.asAscii;

        if(buffer.endsWith("P1")) {
            "P1".postln();
			~advancePhaseState.value();
            buffer = "";
        }
    };

    ~readRoutine.stop;
    ~readRoutine = Routine({
        inf.do({
            var data;
            data = ~arduino.read;
            ~processData.value(data);
            0.01.wait; // Wait for 10ms
        });
    }).play;
};

ServerQuit.add({ 0.exit }); // quit if the button is pressed
