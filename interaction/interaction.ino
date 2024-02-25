#include <Servo.h>

Servo myservo;  // create servo object to control a servo
int kServoOpenValue = 1000;
int kServoCloseValue = 2250;

const int buttonPin = 8;     // the number of the pushbutton pin
const int ledPin =  10;      // the number of the LED pin

// How long button must actually be pressed for
unsigned long kButtonPressRequiredMs = 2000;

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
 *  2 - button pressed for long enough
 *  3 - door opened, waiting for phone to fall
 *  4 - door closed, waiting for waiting music to finish
 **/
int numPhases = 5;
int currentPhaseState = 0;
unsigned long currentPhaseStartTime = 0;

void handlePhaseStateChanged() {
    switch (currentPhaseState) {
        case 0:
            // idle
            break;
        case 1:
            // button pressed, waiting
            break;
        case 2:

            // Send sound computer message to move it to P1
            Serial.println("P1");  

            break;
        case 3:
            // door opened, waiting for phone to fall

            // opens servo
            myservo.writeMicroseconds(kServoOpenValue);

            break;
        case 4:
            // door closed, waiting for waiting music to finish
            // closes servo
            myservo.writeMicroseconds(kServoCloseValue);

            break;
    }
}
void advancePhase() {
    currentPhaseState = (currentPhaseState + 1) % numPhases;
    currentPhaseStartTime = now;
    handlePhaseStateChanged();
}

void handleButtonPress() {
    // turn LED on:
    digitalWrite(ledPin, HIGH);

    // Button press only does something in the idle state
    if (currentPhaseState == 0) {
        advancePhase();
    }
}
void handleButtonRelease() {
    // turn LED off:
    digitalWrite(ledPin, LOW);

    // In phase 1, if button is released, reset the phase
    if (currentPhaseState == 1) {
        currentPhaseState = 0;
        handlePhaseStateChanged();
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
        } else {
            handleButtonRelease();
        }
    }

    currentPhaseDuration = now - currentPhaseStartTime;
    switch (currentPhaseState) {
        case 0:
            // idle
            break;
        case 1:
            // button initially, waiting if it was long enough
            if (currentPhaseDuration > kButtonPressRequiredMs) {
                advancePhase();
            }
            break;
        case 2:
            // button pressed, waiting
            if (currentPhaseDuration > kButtonPressDelayMs) {
                advancePhase();
            }
            break;
        case 3:
            // door opened, waiting for phone to fall
            if (currentPhaseDuration > kDoorOpenDurationMs) {
                advancePhase();
            }
            break;
        case 4:
            // door closed, waiting for waiting music to finish
            if (currentPhaseDuration > kCountdownDurationMs) {
                advancePhase();
            }
            break;
    }
}
