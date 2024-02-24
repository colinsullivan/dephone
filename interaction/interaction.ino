#include <Servo.h>

Servo myservo;  // create servo object to control a servo
int kServoOpenValue = 1000;
int kServoCloseValue = 2150;

const int buttonPin = 8;     // the number of the pushbutton pin
const int ledPin =  10;      // the number of the LED pin

// Time between pressing the button and opening the door
unsigned long kButtonPressDelayMs = 6500;

// Time between opening the door and closing it
unsigned long kDoorOpenDurationMs = 500;

// Time between closing the door and the music finishing
/*unsigned long kCountdownDurationMs = 60000;*/
unsigned long kCountdownDurationMs = 10000;

void setup() {
    // initialize the LED pin as an output:
    // initialize the pushbutton pin as an input:
    pinMode(buttonPin, INPUT_PULLUP);
    // initialize the LED pin as an output:
  pinMode(ledPin, OUTPUT);

    myservo.attach(9);

    // Initialize serial communication at 9600 bits per second:
    Serial.begin(9600);

    myservo.writeMicroseconds(kServoCloseValue);
}

int buttonState = 0;
int prevButtonState = 0;
unsigned long now = millis();

/**
 *  Tracks the current phase
 *  0 - idle
 *  1 - button pressed, waiting
 *  2 - door opened, waiting for phone to fall
 *  3 - door closed, waiting for waiting music to finish
 **/
int numPhases = 4;
int currentPhaseState = 0;
unsigned long currentPhaseStartTime = 0;

void handlePhaseAdvanced() {
    switch (currentPhaseState) {
        case 0:
            // idle
            break;
        case 1:
            // button pressed, waiting

            // Send sound computer message to move it to P1
            Serial.println("P1");  

            break;
        case 2:
            // door opened, waiting for phone to fall

            // opens servo
            myservo.writeMicroseconds(kServoOpenValue);

            break;
        case 3:
            // door closed, waiting for waiting music to finish
            // closes servo
            myservo.writeMicroseconds(kServoCloseValue);

            break;
    }
}
void advancePhase() {
    currentPhaseState = (currentPhaseState + 1) % numPhases;
    currentPhaseStartTime = now;
    handlePhaseAdvanced();
}

void handleButtonPress() {
    // turn LED on:
    digitalWrite(ledPin, HIGH);

    // Button press only does something in the idle state
    if (currentPhaseState == 0) {
        advancePhase();
    }

}

unsigned long currentPhaseDuration = 0;
void loop() {
    now = millis();
    prevButtonState = buttonState;

    // read the state of the pushbutton value:
    buttonState = digitalRead(buttonPin);

    if (prevButtonState != buttonState) {
        if (buttonState == LOW) {
            handleButtonPress();
        }
    }

    currentPhaseDuration = now - currentPhaseStartTime;
    switch (currentPhaseState) {
        case 0:
            // idle
            break;
        case 1:
            // button pressed, waiting
            if (currentPhaseDuration > kButtonPressDelayMs) {
                advancePhase();
            }
            break;
        case 2:
            // door opened, waiting for phone to fall
            if (currentPhaseDuration > kDoorOpenDurationMs) {
                advancePhase();
            }
            break;
        case 3:
            // door closed, waiting for waiting music to finish
            if (currentPhaseDuration > kCountdownDurationMs) {
                advancePhase();
            }
            break;
    }
}
