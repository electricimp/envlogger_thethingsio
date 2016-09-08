#require "TheThingsAPI.class.nut:1.0.1"

// Hardcoded location, can get via Google or Skyhook
lat <- 37.3953745;
long <- -122.1034082;

// Instantiate a thing with an existing token
thing <- TheThingsAPI("<yourAPItoken>");

// Called when device sends a log message
device.on("log", function(data) {
    
    thing.addVar("temp", data.temp, {
        "timestamp" : time(),  
        "geo" : {
            "lat" : lat,
            "long" : long
        }
    });
    thing.addVar("humid", data.humid, {
        "timestamp" : time(),  
        "geo" : {
            "lat" : lat,
            "long" : long
        }
    });
    // Send to TheThings.IO
    thing.write(function(err, resp, data) {
        if (err) {
            server.error(err);
            return;
        }
    });

})

// Called when device sends an alert message
device.on("alert", function(data) {

    if (data.temp == "") {
        thing.addVar("alert", "0", {
            "timestamp" : time(),  
            "geo" : {
                "lat" : lat,
                "long" : long
            }
        });
    } else {
        thing.addVar("alert", "1", {
            "timestamp" : time(),  
            "geo" : {
                "lat" : lat,
                "long" : long
            }
        });
    }
    // Send to TheThings.IO
    thing.write(function(err, resp, data) {
        if (err) {
            server.error(err);
            return;
        }
    });

})

