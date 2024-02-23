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
// ~soundDir = "/root/Bela/projects/dephone-sounds";
~soundDir = "/Users/colin/Projects/dephone/sound";

SerialPort.devices().postln();
~portName = "/dev/ttyACM0";

~experienceSoundsByPhase = [
    [
        "1 - example a.wav",
        "1 - example b.wav"
    ],
    [],
    [
        "1 - example countdown.wav"
    ],
]

s.waitForBoot {
	var buffer = "";

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
        arg out = 0, bufnum, shouldLoop = 0;

        Out.ar(
            out,
            DiskIn.ar(2, bufnum, loop: shouldLoop)
        );
    }).add;

    /**
     *  Sets up state machine
     **/
    ~handlePhaseAdvanced = {
		~experiencePhase.postln();
        if(~experiencePhase == 0, {
			if (~examplePlayer.isNil == false, {
				~examplePlayer.free;
			});
			~exampleABuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~experienceSoundsByPhase[~experiencePhase].choose(), 0, 2);
            ~examplePlayer = Synth.new("stream-buf", [\bufnum, ~exampleABuf, \shouldLoop, 1], s);
        });

        // TODO: phase 2

        if(~experiencePhase == 2, {
            if (~examplePlayer.isNil == false, {
                ~examplePlayer.free;
            });
			~exampleABuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ ~experienceSoundsByPhase[~experiencePhase].choose(), 0, 2);
            ~examplePlayer = Synth.new("stream-buf", [\bufnum, ~exampleABuf], s);
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

    ~arduino = SerialPort(~portName, 9600, crtscts: true);

    /**
     *  Read arduino
     **/
    ~processData = {
        arg data;

        buffer = buffer ++ data.asAscii;

        if(buffer.endsWith("BD")) {
        ~player = {
            BufRd.ar(1, b, SinOsc.ar(0.08) * BufFrames.ir(b))
        }.play;
        buffer = "";
        } {
            if (buffer.endsWith("BU")) {
                ~player.free();
                buffer = "";
            }

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
