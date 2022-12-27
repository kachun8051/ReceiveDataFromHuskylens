#include "HUSKYLENS.h"
//#include "SoftwareSerial.h"
// Add the NeoSWSerial library
#include <NeoSWSerial.h>
// Add alternative software serial library
// Reference: https://www.pjrc.com/teensy/td_libs_AltSoftSerial.html
#include <AltSoftSerial.h>
// Json library
#include <ArduinoJson.h>

HUSKYLENS huskylens;
//SoftwareSerial HSSerial(10, 11); // RX, TX of HuSkyLens
//SoftwareSerial BTSerial(2, 3); // RX, TX of Bluetooth
NeoSWSerial HSSerial( 10, 11); // RX, TX of HuSkyLens
AltSoftSerial BTSerial( 8, 9); // RX, TX of Bluetooth
// DynamicJsonDocument doc(100);
StaticJsonDocument<100> doc;

//HUSKYLENS green line >> Pin 10; blue line >> Pin 11
void printResult(HUSKYLENSResult result);

void setup() {
    Serial.begin(9600);
    HSSerial.begin(9600);  
    BTSerial.begin(9600);      
    while (!huskylens.begin(HSSerial))
    {
        Serial.println(F("Begin failed!"));
        Serial.println(F("1.Please recheck the \"Protocol Type\" in HUSKYLENS (General Settings>>Protocol Type>>Serial 9600)"));
        Serial.println(F("2.Please recheck the connection."));
        delay(200);
    }
    String arrObject[] = {
      "Nothing", "Pork Slice", "Beef Slice", "Tenderloin", "Squid", 
      "Green Shrimp", "Safflower Crab", "Bream Fish", "Lobster", "Portunus"
    };  
    for (int i = 0; i < 10; i++) {
      int j = i+1;       
      while(!huskylens.setCustomName(arrObject[i],i+1)) {
        String msg = "ID" + String(i+1) + " customname (i.e. " + arrObject[i] + ") failed!";
        Serial.println(msg); 
        delay(100);        
      }
    }
}

void loop() {
    if (!huskylens.request()) Serial.println(F("Fail to request data from HUSKYLENS, recheck the connection!"));
    else if(!huskylens.isLearned()) Serial.println(F("Nothing learned, press learn button on HUSKYLENS to learn one!"));
    else if(!huskylens.available()) Serial.println(F("No block or arrow appears on the screen!"));
    else
    {
        Serial.println(F("###########"));
        while (huskylens.available())
        {
            HUSKYLENSResult result = huskylens.read();
            printResult(result);
            delay(500);
        }    
    }
}

void printResult(HUSKYLENSResult result){
  doc.clear();
    if (result.command == COMMAND_RETURN_BLOCK){
        doc["xCenter"] = result.xCenter;
        doc["yCenter"] = result.yCenter;
        doc["width"] = result.width;
        doc["height"] = result.height;
        doc["id"] = result.ID;
        serializeJson(doc, Serial);        
        serializeJson(doc, BTSerial);        
    }
    else if (result.command == COMMAND_RETURN_ARROW){
        doc["xOrigin"] = result.xOrigin;
        doc["yOrigin"] = result.yOrigin;
        doc["xTarget"] = result.xTarget;
        doc["yTarget"] = result.yTarget;
        doc["id"] = result.ID;
        serializeJson(doc, Serial);   
        serializeJson(doc, BTSerial);
    }
    else{
        doc["id"] = 0;
        serializeJson(doc, Serial);  
        serializeJson(doc, BTSerial);            
        //Serial.println("Object unknown!");
    }
    //Serial.flush();
    //BTSerial.flush();
}