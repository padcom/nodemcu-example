#include <Wire.h>

// A simple interrupt-driven receiver 

#define PULSE     350
#define SIGMA     (PULSE/2)
#define PREAMBLE  31
#define LONG      3
#define SHORT     1
#define BITS      24

void setup() {
  Serial.begin(115200); 

  // Configure debug LED that blinks on RF input change
  pinMode(13, OUTPUT);

  // Configure RF input with internal pullup resistor
  pinMode(2, INPUT_PULLUP);

  // Configure notification pin 5
  pinMode(5, OUTPUT);

  // Configure i2c slave mode
  Wire.begin(8);
  Wire.onRequest(sendReceivedCode);

  // Start receibing data
  attachInterrupt(0, DI0_ISR, CHANGE);

  Serial.println("Ready.\n");
}

bool found   = false;
long code    = 0;
long codeTs  = 0;

void loop() {
  if (found) {
    Serial.println(code);
    found = false;
    if (abs(millis() - codeTs) > 100) {
      digitalWrite(5, 0);
    } else {
      digitalWrite(5, 1);
    }
  } else {
    digitalWrite(5, 0);
  }
}

void sendReceivedCode() {
  char result[9];
  sprintf(result, "% 8lu", code);
  code = 0;
  Wire.print(result);
}

int  state  = 0;
long prev   = 0;
int  nibble = 0;
int  bits   = 0;
long value   = 0;

#define STATE_WAIT_PREAMBLE       0
#define STATE_READ_WIRE_BIT_HIGH  1
#define STATE_READ_WIRE_BIT_LOW   2

void DI0_ISR() {
  // toggle internal LED to show the state of RF input changed
  PORTB ^= (1 << PB5);

  long curr = micros();
  long len = curr - prev;
  prev = curr;

  switch (state) {
    case STATE_WAIT_PREAMBLE:
      if (abs(len - (PULSE * PREAMBLE)) < SIGMA) {
        value = 0;
        bits  = 0;
        state = STATE_READ_WIRE_BIT_HIGH;
      }
      break;
    case STATE_READ_WIRE_BIT_HIGH:
      // read higher wire bit
      if (abs(len - (PULSE * LONG)) < SIGMA) {
        nibble = 30;
        state = STATE_READ_WIRE_BIT_LOW;
      } else if (abs(len - (PULSE * SHORT)) < SIGMA) {
        nibble = 10;
        state = STATE_READ_WIRE_BIT_LOW;
      } else {
        state = STATE_WAIT_PREAMBLE;
      }
      break;
    case STATE_READ_WIRE_BIT_LOW:
      // read lower wire bit
      if (abs(len - (PULSE * LONG)) < SIGMA) {
        nibble += 3;
        state = STATE_READ_WIRE_BIT_HIGH;
      } else if (abs(len - (PULSE * SHORT)) < SIGMA) {
        nibble += 1;
        state = STATE_READ_WIRE_BIT_HIGH;
      } else {
        state = STATE_WAIT_PREAMBLE;
      }

      // decode wire bits to data bits
      if (state == STATE_READ_WIRE_BIT_HIGH) {
        if (nibble == 13) {
          bits++; value <<= 1;
        } else if (nibble == 31) {
          bits++; value <<= 1; value |= 1;
        } else {
          state = STATE_WAIT_PREAMBLE;
        }
      }

      // entire value has been read
      if (state == STATE_READ_WIRE_BIT_HIGH && bits == BITS) {
        found  = true;
        code   = value;
        codeTs = millis();
        state = STATE_WAIT_PREAMBLE;
      }
      break;
    default:
      state = STATE_WAIT_PREAMBLE;
      break;
  }
}

