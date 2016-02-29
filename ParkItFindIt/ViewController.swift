//
//  ViewController.swift
//  ParkItFindIt
//
//  Created by JOHN TAN on 2/24/16.
//  Copyright © 2016 ObjSpace. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //Outlet
    @IBOutlet weak var parkItButton: UIButton!
    @IBOutlet weak var UnparkButton: UIButton!
    @IBOutlet weak var findItButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var meterTimeTextField: UITextField!
    @IBOutlet weak var timerDisplay: UILabel!
    
    
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    let mapItem = MKMapItem()
    let pin = MKPointAnnotation()
    
    var timer = NSTimer()
    var meterTime = Int()
    var displayMeterTime = Int()
    var meterTimeEntered = Int?()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    
        
        // Check for pre-existing "parkingSpot"
        checkForSavedParkingSpot()
    }
    
    func checkForSavedParkingSpot(){
        //checking if there is an object for the key "parkingSpot" that we've previously saved
        //if so, load it and put a pin there. if not, do nothing
        if let loadedParkingSpot = defaults.dataForKey("parkingSpot"){
            if let loadedParkingSpot = NSKeyedUnarchiver.unarchiveObjectWithData(loadedParkingSpot) as? CLLocation{
                let savedParkingSpot = CLLocationCoordinate2DMake(loadedParkingSpot.coordinate.latitude, loadedParkingSpot.coordinate.longitude)
                pin.coordinate = savedParkingSpot
                pin.title = "Car Parked Here"
                mapView.addAnnotation(pin)
                print(pin.coordinate.latitude)
                print(pin.coordinate.longitude)
                self.parkItButton.hidden = true
                self.UnparkButton.hidden = false
                self.mapView.hidden = false
                self.findItButton.hidden = false
            }
        }
    }
    
    //2 location manager functions - react to an error location user and one to update location
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Could not find your locaiton")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpanMake(0.02, 0.02)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    //drop pin at location
    func dropPinAtLocation(){
        let locValue = locationManager.location!
        let locationData = NSKeyedArchiver.archivedDataWithRootObject(locValue)
        defaults.setObject(locationData, forKey: "parkingSpot")
        pin.coordinate = CLLocationCoordinate2DMake(locValue.coordinate.latitude, locValue.coordinate.longitude)
        pin.title = "Car Parked Here"
        mapView.addAnnotation(pin)
    }
    
    func displayAreYouSureAlert(){
        let alertController = UIAlertController(title: "Unpark Car", message: "Are you sure you want to unpark your car?", preferredStyle: .Alert)
        //if user clicks OK, set our saved value to nil, remove pin, and rearrange buttons
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            (action: UIAlertAction!) in
            self.defaults.setObject(nil, forKey: "parkingSpot")
            self.timer.invalidate()
            self.mapView.removeAnnotation(self.pin)
            self.timerDisplay.hidden = true
            self.parkItButton.hidden = false
            self.UnparkButton.hidden = true
            self.mapView.hidden = false
            self.findItButton.hidden = true
        }))
        
        //if user clicks anser, don't do anything (leave the old parking spot)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (action: UIAlertAction!) in
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //timer based alerts
    func displayAlertMeterTime(){
        timer.invalidate()
        
        let meterAlertController = UIAlertController(title: "Meter Parking", message: "Would you like to set a meter reminder?", preferredStyle: .Alert)
        
        //if user selects OK UI buttons are hidden and text fields appears to allow the user to enter a time which will captured by meterTime.
        meterAlertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            (action: UIAlertAction!) in
            self.meterTimeTextField.hidden = false
            self.parkItButton.hidden = true
            self.UnparkButton.hidden = true
            self.mapView.hidden = true
            self.findItButton.hidden = true
        }))
        
        //if user clicks NO Thanks, no timer is set and basic functionality resumes
        meterAlertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (action: UIAlertAction!) in
            self.parkItButton.hidden = true
            self.UnparkButton.hidden = false
            self.mapView.hidden = false
            self.findItButton.hidden = false
            self.meterTimeTextField.hidden = true
        }))
        self.presentViewController(meterAlertController, animated: true, completion: nil)
    }
    
    func nilTextFieldEntryAlert(){
        let nilTextFieldEntryAlertController = UIAlertController(title: "Invalid Entry!", message: "Would you like to try again?", preferredStyle: .Alert)
        //if user selects OK user is again given the option to enter an amount of time
        nilTextFieldEntryAlertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            (action: UIAlertAction!) in
            self.timerDisplay.hidden = true
            self.parkItButton.hidden = true
            self.UnparkButton.hidden = true
            self.mapView.hidden = true
            self.findItButton.hidden = true
            self.meterTimeTextField.hidden = false
        }))
        //if user clicks NO no timer is set and basic functionality resumes
        nilTextFieldEntryAlertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (action: UIAlertAction!) in
            self.parkItButton.hidden = true
            self.UnparkButton.hidden = false
            self.mapView.hidden = false
            self.findItButton.hidden = false
            self.meterTimeTextField.hidden = true
        }))
        self.presentViewController(nilTextFieldEntryAlertController, animated: true, completion: nil)
    }
    
    func timesUpAlert(){
        let meterTimeAlertController = UIAlertController(title: "Times Up!", message: "Head back to your car now", preferredStyle: .Alert)
        meterTimeAlertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
            (action: UIAlertAction!) in
            self.timerDisplay.text = "Meter Has Expired"
            self.meterTime == 0
        }))
        self.presentViewController(meterTimeAlertController, animated: true, completion: nil)
    }
    
    func startTime(){
            meterTimeEntered = Int(meterTimeTextField.text ?? " ") ?? 0
            if meterTimeEntered != 0 {
                meterTime = (meterTimeEntered! * 60)
                timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
                self.timerDisplay.hidden = false
                self.meterTimeTextField.hidden = true
            } else {
                nilTextFieldEntryAlert()
            }
    }
    
    func updateCounter(){
        meterTime--
        if meterTime > 60{
            displayMeterTime = ((meterTime/60)+1)
            timerDisplay.text = String("\(displayMeterTime) Minutes Left")
        } else if meterTime <= 1{
            timerDisplay.text = "Less than 1 Minute Left"
        } else {
            timer.invalidate()
            timesUpAlert()
            timerDisplay.hidden = true
        }
    }
    
    //parking/unparking buttons
    @IBAction func parkItButtonPressed(sender: AnyObject) {
        displayAlertMeterTime()
        
        if defaults.objectForKey("parkingSpot") == nil{
            dropPinAtLocation()
        }
    }
    
    @IBAction func unparkButtonPressed(sender: AnyObject) {
        displayAreYouSureAlert()

        
        if defaults.objectForKey("parkingSpot") != nil{
            self.mapView.removeAnnotation(self.pin)
        }
    }
    
    
    
    //helper function to load some options in native maps
    func openInMapsTransit(coordinate: CLLocationCoordinate2D){
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Car Parked Here"
        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeWalking]
        mapItem.openInMapsWithLaunchOptions(launchOptions)
    }
    
    //open parking location and load with options in native maps
    @IBAction func openAppleMaps(sender: AnyObject) {
        if let loadedParkingSpot = defaults.dataForKey("parkingSpot"){
            if let loadedParkingSpot = NSKeyedUnarchiver.unarchiveObjectWithData(loadedParkingSpot) as? CLLocation{
                let savedParkingSpot = CLLocationCoordinate2DMake(loadedParkingSpot.coordinate.latitude, loadedParkingSpot.coordinate.longitude)
                openInMapsTransit(savedParkingSpot)
            }
        }
    }
    
    
    @IBAction func backgroundTap(sender: UIControl) {
        
        
        if  meterTime > 0{
        } else {
            if meterTimeTextField != nil{
                meterTimeTextField.resignFirstResponder()
                startTime()
                timerDisplay.text = String(displayMeterTime)
                self.parkItButton.hidden = true
                self.UnparkButton.hidden = false
                self.mapView.hidden = false
                self.findItButton.hidden = false
                self.timerDisplay.hidden = false
                //self.meterTimeTextField.hidden = true
               // meterTimeTextField = nil
            }
            else {
                //nilTextFieldEntryAlert()
            }
        }
    }
    
    

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    


}

