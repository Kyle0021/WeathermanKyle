//
//  RestConnector.swift
//  Weatherman Kyle
//
//  Created by Kyle Carlos Fernandez on 2019/07/03.
//  Copyright © 2019 Kyle. All rights reserved.
//

import Foundation

class RestConnector
{
    // api delegate setup
    var delegate: RestDelegate?
    init(delegate: RestDelegate?)
    {
        self.delegate = delegate
    }
    
    // this method is called to perform the API Call to the Dark Sky API
    // the coordinates are sent in, as well as a units preference e.g "si" returns metric units
    func getMethod(lat: Double, lon: Double, units: String)
    {
        
        // Set up the URL request
        // Builds a string using the Dark Sky url, my API key, and the information I send in with the getMethod() call.
        let URLString: String = "https://api.darksky.net/forecast/4aaa4e6f974de4a0b203a05d6be6d735/" + String(lat) + "," + String(lon) + "?units=" + units
        
        print(URLString)
        
        // URL components to encode the string because it contains special characters.
        let components = transformURLString(URLString)
        
        guard let url = components?.url else {
            print("Error: cannot create URL")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        
        // set up the session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET")
                print(error!)
                return
            }
            // make sure we have data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON
            do {
                guard let parsed = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }
                self.delegate?.onPostExecute(parsed as NSDictionary)
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    
    // encode url, because it contains special characters swift is unable to create the URL
    func transformURLString(_ string: String) -> URLComponents? {
        guard let urlPath = string.components(separatedBy: "?").first else {
            return nil
        }
        var components = URLComponents(string: urlPath)
        if let queryString = string.components(separatedBy: "?").last {
            components?.queryItems = []
            let queryItems = queryString.components(separatedBy: "&")
            for queryItem in queryItems {
                guard let itemName = queryItem.components(separatedBy: "=").first,
                    let itemValue = queryItem.components(separatedBy: "=").last else {
                        continue
                }
                components?.queryItems?.append(URLQueryItem(name: itemName, value: itemValue))
            }
        }
        return components!
    }
}

