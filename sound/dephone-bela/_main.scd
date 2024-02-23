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

s.waitForBoot {
	var buffer = "";
	// Your code goes here.
	b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

SerialPort.devices().postln();
~portName = "/dev/ttyACM0";

~arduino = SerialPort(~portName, 9600, crtscts: true);



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
