(
SynthDef("stream-buf", {
	arg out = 0, bufnum;

	Out.ar(
		out,
		DiskIn.ar(2, bufnum)
	);
}).add;
)

(
~soundDir = "/Users/colin/Projects/dephone/sound";
~exampleABuf = Buffer.cueSoundFile(s, ~soundDir +/+ "renders" +/+ "1 - example a.wav", 0, 2);
)

(
~examplePlayer = Synth.new("stream-buf", [\bufnum, ~exampleABuf], s);
)

(
~examplePlayer.free();
)

(
SerialPort.devices().postln();
~portName = "/dev/cu.usbmodem444201";

~arduino = SerialPort(~portName, 9600, crtscts: true);

)

(
SerialPort.closeAll();
)

(

var buffer = "";
~processData = {
	arg data;

	buffer = buffer ++ data.asAscii;

	if(buffer.endsWith("BD")) {
		~examplePlayer = Synth.new("stream-buf", [\bufnum, ~exampleABuf], s);
		buffer = "";
	} {
		if (buffer.endsWith("BU")) {
			~examplePlayer.free();
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
)

(
~readRoutine.stop;
)

(
"B".ascii
)

(
~advancePhaseState.value();
)

(
["one", "two"].choose()
)

(
10 + rand(20)
)
