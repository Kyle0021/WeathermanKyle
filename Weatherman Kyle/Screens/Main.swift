//
//  ViewController.swift
//  Weatherman Kyle
//
//  Created by Kyle Carlos Fernandez on 2019/07/03.
//  Copyright © 2019 Kyle. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class Main: UIViewController, RestDelegate, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate  {
    
    //Linked UI Objects
    @IBOutlet var lblLocation: UILabel!
    @IBOutlet var lblCurrentTemp: UILabel!
    @IBOutlet var lblSummaryConditions: UILabel!
    @IBOutlet var lblHumidity: UILabel!
    @IBOutlet var lblWind: UILabel!
    @IBOutlet var colView: UICollectionView!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var btnRefresh: UIButton!
    @IBOutlet var weatherImage: UIImageView!
    @IBOutlet var btnSearch: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    
    //Location stuff
    let locationManager = CLLocationManager()
    let units = "si"
    
    //Storage Vars
    var currentWeatherData: NSDictionary!
    var dailyWeatherData: [NSDictionary]!
    var currentLocation: CLLocation!
    
    //UserDefaults if user chooses to not use their own location
    let defaults = UserDefaults.standard
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // On start-up show the loading view while the data is being prepared.
        searchBar.delegate = self
        searchBar.placeholder = "Enter your suburb or city name"
        loadingView.isHidden = false
        colView.isHidden = true
        
        
        if defaults.value(forKey: "CustomLocation") != nil
        {
            if defaults.value(forKey: "CustomLocation") as! String == "true"
            {
                let connector = RestConnector(delegate: self)
                connector.getMethod(lat: self.defaults.value(forKey: "Latitude") as! Double, lon: self.defaults.value(forKey: "Longitude") as! Double, units: self.units)
                self.lblLocation.text = defaults.value(forKey: "Location") as? String
            }
            else
            {
                getLocation()
            }
        }
        else
        {
            getLocation()
        }
    }
    
    // Allows the user to refresh their weather information
    @IBAction func actionRefresh(_ sender: Any)
    {
        if defaults.value(forKey: "CustomLocation") != nil
        {
            let alert = UIAlertController(title: "Update Weather Forecast", message: "You can refresh the current weather forecast or fetch the Weather forecast for your currrent location", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Refresh", style: .default, handler: { action in
                
                let connector = RestConnector(delegate: self)
                connector.getMethod(lat: self.defaults.value(forKey: "Latitude") as! Double, lon: self.defaults.value(forKey: "Longitude") as! Double, units: self.units)
                
            }))
            alert.addAction(UIAlertAction(title: "Current Location", style: .default, handler: { action in
                
                self.defaults.setValue("false", forKeyPath: "CustomLocation")
                
                self.loadingView.isHidden = false
                self.colView.isHidden = true
                self.locationManager.stopUpdatingLocation()
                self.getLocation()
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            self.loadingView.isHidden = false
            self.colView.isHidden = true
            self.locationManager.stopUpdatingLocation()
            self.getLocation()
        }
    }
    
    // Results that came from API call
    func onPostExecute(_ response: NSDictionary)
    {
        // Set the information related to the current weather conditions for your location
        if response["currently"] != nil
        {
            currentWeatherData = response["currently"] as? NSDictionary
            
            DispatchQueue.main.async
            {
                self.lblCurrentTemp.text = String(Int((round(self.currentWeatherData["temperature"]! as! Double)))) + "°C"
                self.lblSummaryConditions.text = self.currentWeatherData["summary"]! as? String
                self.lblHumidity.text = "Humidity: " + String(Int(round((self.currentWeatherData["humidity"]! as! Double) * 100))) + "%"
                self.lblWind.text = "Wind: " + String(Int(round((self.currentWeatherData["windSpeed"]! as! Double) * 3.6))) + "km/h"
                self.weatherImage.image = GetWeatherImage().getImage(icon: (self.currentWeatherData["icon"]! as? String)!)
                self.weatherImage.isHidden = false
            }
        }
        // Get the forecasted weather information
        if response["daily"] != nil
        {
            dailyWeatherData = (response["daily"] as! NSDictionary)["data"] as? [NSDictionary]
            
            DispatchQueue.main.async
            {
                // Reload collectionview
                // Hide the loadingview as the data is ready
                self.colView.delegate = self
                self.colView.dataSource = self
                self.colView.reloadData()
                self.colView.isHidden = false
                self.loadingView.isHidden = true
            }
        }
    }
    
    // Use the Location Manager auth status to check if user has aquired permission for the app to use their location
    // If the user's status is has not be determined, request permission to use their location - appropriate message set in the .plist file.
    // Begin updating the user's location
    func getLocation()
    {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            return
            
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location services are currently disabled", message: "Please enable your location services for WeathermanKyle in privacy settings", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            present(alert, animated: true, completion: nil)
            return
            
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            break
            
        @unknown default:
            fatalError()
        }
    }
    
    // Once the location manager has updated the current location, this function will send the latitude and longitude values to the RestConnector.
    // The getPlace method is then called, this method get the address name of the coordinates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }

        let lat = locValue.latitude
        let lon = locValue.longitude
        
        let connector = RestConnector(delegate: self)
        connector.getMethod(lat: lat, lon: lon, units: units)
        getPlaceFromCoordinates(location: manager.location!)
    }
    
     // Geocode gets the address of the current location using the coordinates, that address has properties that give us the suburb and province.
    // The location label is then updated with the new user readable location.
    func getPlaceFromCoordinates(location:CLLocation)
    {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error)->Void in
            var placemark:CLPlacemark!
            
            if error == nil && placemarks!.count > 0 {
                placemark = placemarks![0] as CLPlacemark
                
                var addressString : String = ""
               
                    if placemark.locality != nil {
                        addressString = addressString + placemark.locality! + ", "
                    }
                    if placemark.administrativeArea != nil {
                        addressString = addressString + placemark.administrativeArea! + " "
                    }
                
                self.lblLocation.text = addressString
                self.defaults.setValue(addressString, forKeyPath: "Location")
            }
        })
    }
    
    // CollectionView Methods
    // Set 1 section for the collectionview
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    // I set the daily forecasted count as the number of items/rows in the collectionview
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return dailyWeatherData.count
    }
    
    // Populate our collectionview cells with our daily forecast information.
    // I use the indexPath to specify which daily forecast information gets added to each cell.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = colView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! WeatherCell
        
        // Temporary Dictionary that  stores the daily forecasted information at the current indexPath.row.
        var tempDictionary: NSDictionary!
        tempDictionary = dailyWeatherData![indexPath.row]
        
        // Get readable date from the unix timestamp given.
        let date = Date(timeIntervalSince1970: tempDictionary["time"]! as! TimeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+02:00")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "EE, d MMM"
        let strDate = dateFormatter.string(from: date)
        cell.date.text = strDate
        
        // Set the rest of our values
        // The wind speed is calculated in meters per second, so I have to convert that to km/h.
        // I round the humidity values and multiply them by 100 to get our humidity percentage.
        // I use my GetWeatherImage class and getImage function to retrieve the correct images to be displayed on each row.
        cell.temp.text = "Min: " + String(Int((round(tempDictionary["temperatureMin"]! as! Double)))) + "°  Max: " + String(Int((round(tempDictionary["temperatureMax"]! as! Double)))) + "°"
        
        cell.wind.text = "Wind: " + String(Int(round((tempDictionary["windSpeed"]! as! Double) * 3.6))) + "km/h"
        
        cell.humidity.text = "Humidity: " + String(Int(round((tempDictionary["humidity"]! as! Double) * 100))) + "%"
        
        cell.weatherImage.image = GetWeatherImage().getImage(icon: tempDictionary["icon"]! as! String)
        
        cell.frame.size.width = UIScreen.main.bounds.size.width
        cell.frame.origin.x = 0
        
        return cell
    }
    
    @IBAction func tapSearch(_ sender: Any)
    {
        searchBar.isHidden = false
        searchBar.becomeFirstResponder()
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool
    {
        self.searchBar.isHidden = true
        getCoordinatesFromPlace(place: searchBar.text!)
        
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.isHidden = true
        getCoordinatesFromPlace(place: searchBar.text!)
    }
    
    func getCoordinatesFromPlace(place: String)
    {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(place) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                    
                    let alert = UIAlertController(title: "Location Search", message: "We were unable to match a geograhical location. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.searchBar.isHidden = false
                        self.searchBar.becomeFirstResponder()
                    }))
                    self.present(alert, animated: true, completion: nil)
                    
                    return
            }
            
            // update weather information based on entered location.
            self.searchBar.isHidden = true
            
            let locationObject = CLLocation.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            self.getPlaceFromCoordinates(location: locationObject)
            
            self.defaults.setValue("true", forKeyPath: "CustomLocation")
            self.defaults.setValue(location.coordinate.latitude, forKeyPath: "Latitude")
            self.defaults.setValue(location.coordinate.longitude, forKeyPath: "Longitude")
            
            let connector = RestConnector(delegate: self)
            connector.getMethod(lat: locationObject.coordinate.latitude, lon: locationObject.coordinate.longitude, units: self.units)
        }
        
    }
}

