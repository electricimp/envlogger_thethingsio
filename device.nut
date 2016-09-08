#require "Si702x.class.nut:1.0.0"

alert <- false; 

// Array to compute averages
const ARRSIZE = 5; 
tempArr <- array(ARRSIZE);
humidArr <- array(ARRSIZE);
for (local i=0; i<ARRSIZE; i++) {
    tempArr[i] = 0.0;
    humidArr[i] = 0.0;
}
idx <- -1;

// Temp and humidity thresholds
const TEMPTHRES = 27.0;
const HUMIDTHRES = 60.0;

// Initialize I2C and sensor
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);
tempHumid <- Si702x(hardware.i2c89);

// Heartbeat blink
function blinkHeartbeat() {
    ledPin.write(1);
    imp.sleep(0.5);
    ledPin.write(0);
}

// Alert blink
function blinkAlert() {
    for (local i = 5; i--; i >0) {
        ledPin.write(1);
        imp.sleep(0.05);
        ledPin.write(0);
        imp.sleep(0.05);
    }
}

// Periodically get data
function getData() {
    imp.wakeup(1, getData); // schedule next call
    
    tempHumid.read(function(result) {
        if ("err" in result) {
            server.error(result.err);
            return;
        }
        
        // Move to next slot and store values
        idx++;
        if (idx >= ARRSIZE) idx = 0;
        tempArr[idx] = result.temperature;
        humidArr[idx] = result.humidity;

        if (!alert) {
            blinkHeartbeat()
        } else {
            blinkAlert();
        }

        doLog();
        doAlert();

    });
}

// Log and send to agent
function doLog() {

    //******************* logging **********************
    local eventData = {};
    eventData.temp <- "";
    eventData.humid <- "";

    // Copy to table
    eventData.temp = format("%.1f", tempArr[idx]);
    eventData.humid = format("%.0f", humidArr[idx]);
    server.log("temp: " + eventData.temp + "C, humid: " + eventData.humid + "%");

    // Send message to agent
    agent.send("log", eventData);

}

// Alert and send to agent
function doAlert() {

    //******************* alerting **********************
    local eventData = {};
    eventData.temp <- "";
    eventData.humid <- "";
    
    local avgTemp = 0.0;
    local avgHumid = 0.0;

    // Compute averages
    for (local i=0; i<ARRSIZE; i++) {
        avgTemp += tempArr[i];
        avgHumid += humidArr[i];
    }
    avgTemp = avgTemp / ARRSIZE;
    avgHumid = avgHumid / ARRSIZE;

    if ((avgTemp >= TEMPTHRES) && (avgHumid >= HUMIDTHRES)) {
        alert = true;

        // Copy to table
        eventData.temp = format("%.1f", avgTemp);
        eventData.humid = format("%.0f", avgHumid);
        server.log("ALERT! avg temp: " + eventData.temp + "C, avg humid: " + eventData.humid + "%");
    
        // Send message to agent
        agent.send("alert", eventData);
    } else {
        alert = false
        agent.send("alert", eventData);
    }

}



// Configure LED
ledPin <- hardware.pin2;
ledPin.configure(DIGITAL_OUT, 0);

// Now bootstrap the loop
imp.wakeup(2, getData);
