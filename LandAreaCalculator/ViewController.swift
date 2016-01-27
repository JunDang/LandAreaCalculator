//
//  ViewController.swift
//  LandAreaCalculator
//
//  Created by Yuan Yinhuan on 15/11/23.
//  Copyright © 2015年 Jun Dang. All rights reserved.
//

import UIKit
import GoogleMaps

enum MapType: Int {
    case Normal = 0
    case Terrain
    case Hybrid
}


class ViewController: UIViewController, UIGestureRecognizerDelegate, UISearchBarDelegate, UIActionSheetDelegate, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var addressInput: UISearchBar!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    var marker = GMSMarker()
    var projection = GMSProjection()
    var points: [CLLocationCoordinate2D]=[]
    var path = GMSMutablePath()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initMapView()
        addressInput.delegate = self
        mapView!.delegate = self
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initMapView() {
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(43.7,
            longitude: -79.4, zoom: 6)
        mapView.camera = camera
        marker.position = CLLocationCoordinate2DMake(43.7, -79.4)
        marker.title = "Toronto"
        marker.snippet = "Canada"
        marker.map = mapView
        
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: "action:")
        uilpgr.delegate = self
        uilpgr.minimumPressDuration = 0.5
        mapView!.addGestureRecognizer(uilpgr)
        
    }
    func searchBarSearchButtonClicked(addressInput: UISearchBar) {
        addressInput.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
        DataManager.getLocationFromGoogle(addressInput.text!, success: {(LocationData) -> Void in
            let json = JSON(data: LocationData)
            if json["status"] != "ZERO_RESULTS" {
                let longitudeX = json["results"][0]["geometry"]["location"]["lng"].double!
                let latitudeY = json["results"][0]["geometry"]["location"]["lat"].double!
                let coordinate = CLLocationCoordinate2DMake(latitudeY, longitudeX)
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView!.camera = GMSCameraPosition.cameraWithTarget(coordinate, zoom: 12.0)
                    self.marker.position = coordinate
                    self.marker.title = "\(addressInput.text)"
                    self.marker.map = self.mapView
                    
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    let myAlert = UIAlertController(title: nil, message: "Address not found", preferredStyle: .Alert)
                    let action = UIAlertAction(
                        title: "OK",
                        style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    myAlert.addAction(action)
                    self.presentViewController(myAlert, animated: true, completion: nil)
                }
            }
        })
        
        
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func action(gestureRecoginizer: UIGestureRecognizer){
        
        
        if gestureRecoginizer.state == UIGestureRecognizerState.Began {
            //self.mapView?.clear()
            let touchPoint = gestureRecoginizer.locationInView(self.mapView)
            let newPoint = self.mapView?.convertPoint(touchPoint, fromView: self.mapView)
            let newCoordinate = self.mapView.projection.coordinateForPoint(newPoint!)
            points.append(newCoordinate)
            let marker = GMSMarker(position: newCoordinate)
            marker.icon = UIImage(named: "red-Pin-icon")
            marker.map = mapView
            
            path.addCoordinate(newCoordinate)
            
            if (points.count == 2) {
                let polyline = GMSPolyline(path: path)
                polyline.map = mapView
            } else if (points.count >= 3) {
                self.mapView?.clear()
                for (var i = 0; i < points.count; i++){
                    let pointCoordinate = CLLocationCoordinate2DMake(points[i].latitude, points[i].longitude)
                    let marker = GMSMarker(position: pointCoordinate)
                    marker.icon = UIImage(named: "red-Pin-icon")
                    marker.map = mapView
                    
                }
                let polygon = GMSPolygon(path: path)
                polygon.map = mapView
            }
            
        }
        
    }


    @IBAction func segmentChanged(sender: AnyObject) {
        let mapType = MapType(rawValue: mapTypeSegmentedControl.selectedSegmentIndex)
        switch (mapType!) {
        case .Normal:
            mapView!.mapType = GoogleMaps.kGMSTypeNormal
        case .Terrain:
            mapView!.mapType = GoogleMaps.kGMSTypeTerrain
        case .Hybrid:
            mapView!.mapType = GoogleMaps.kGMSTypeHybrid
        }

        
    }
    
    
    @IBAction func calculateButtonPressed(sender: AnyObject) {
        if points.isEmpty {
            displayNowPointsMessage()
        
        } else {
            points.append(points[0])
            let area = abs(ringArea(points))
            let distance = abs(geoDistance(points))
            let calculatedArea = (round(area*1000))/1000
            let calculatedDistance = (round(distance*1000))/1000
            let calculatedAcre = (round(area*0.000247105*1000))/1000
            let calculatedSquareKilo = (round(area/1000000*1000))/1000
            let calculatedSquareFoot = (round(area*10.7639*1000))/1000
            let calculatedSquareMile = (round(area*0.00000038610215855*1000))/1000
            let calculatedKilo = (round(distance/1000*1000))/1000
            let calculatedFoot = (round(distance*3.28084)*1000)/1000
            let calculatedMile = (round(distance*0.00062137119224*1000))/1000
            let userMessage = "The area is around: \(calculatedArea) square meter, \(calculatedSquareKilo) square kilometer, \(calculatedSquareFoot) square foot, \(calculatedSquareMile) square mile, or \(calculatedAcre) acre. The perimeter is around: \(calculatedDistance) meter, \(calculatedKilo) kilometer, \(calculatedFoot) feet, or \(calculatedMile) mile."
            let myAlert = UIAlertController(title: "Results", message: userMessage, preferredStyle: .Alert)
            let action = UIAlertAction(
                title: "OK",
                style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
            }
            myAlert.addAction(action)
            presentViewController(myAlert, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        if points.isEmpty {
            displayNowPointsMessage()
            
        } else {
        self.mapView?.clear()
        points = []
        path = GMSMutablePath()
        }
    }
    
    func displayNowPointsMessage() {
        let userMessage = " Please long press on your start point and place a pin on the map, followed by all the subsequent points along the outside edge of the shape of your land, then press the calculator button."
        let myAlert = UIAlertController(title: "Notice", message: userMessage, preferredStyle: .Alert)
        let action = UIAlertAction(
            title: "OK",
            style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
        }
        myAlert.addAction(action)
        presentViewController(myAlert, animated: true, completion: nil)

        
    }

    
    //calculate area
    func ringArea(points:[CLLocationCoordinate2D]) -> Double {
        var area: Double = 0.0
        
        if (points.count > 2) {
            var p1: CLLocationCoordinate2D = points[0]
            var p2: CLLocationCoordinate2D = points[1]
            
            for (var i = 0; i < points.count - 1; i++) {
                p1 = points[i]
                p2 = points[i + 1]
                area += rad(p2.longitude - p1.longitude) * (2 + sin(rad(p1.latitude)) + sin(rad(p2.latitude)))
            }
            
            area = area * 6378137 * 6378137 / 2;
        }
        
        return area
    }
    
    func rad(x: Double) -> Double {
        return x * M_PI / 180;
    }
    
    //calculate distance
    func geoDistance(points:[CLLocationCoordinate2D]) -> Double {
        var distance: Double = 0.0
        let EARTH_RADIUS = 6378137.0
        if (points.count >= 2) {
            var p1: CLLocationCoordinate2D = points[0]
            var p2: CLLocationCoordinate2D = points[1]
            for (var i = 0; i < points.count - 1; i++) {
                p1 = points[i]
                p2 = points[i + 1]
                let lat1 = rad(p1.latitude)
                let lat2 = rad(p2.latitude)
                let lng1 = rad(p1.longitude)
                let lng2 = rad(p2.longitude)
                distance += EARTH_RADIUS * acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lng1 - lng2))
            }
        }
        return distance
    }
    
    

}

