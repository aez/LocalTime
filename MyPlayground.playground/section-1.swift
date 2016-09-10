// Playground - noun: a place where people can play

import UIKit
import CoreLocation

var str = "Hello, playground"

let now = NSDate()
now.timeIntervalSinceReferenceDate


let lm = CLLocationManager()
lm.delegate =
lm.startUpdatingLocation()