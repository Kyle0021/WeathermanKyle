//
//  GetWeatherImage.swift
//  Weatherman Kyle
//
//  Created by Kyle Carlos Fernandez on 2019/07/05.
//  Copyright © 2019 Kyle. All rights reserved.
//

import Foundation
import UIKit

// Takes a string for the icon name from the DarkSky returned data. Based on list of valid icon names in the DarkSky API.
// Uses a switch to then find the matching icon name.
// Returns the appropriate image for that icon name.
// Sets a default image if there is no matching name, as DarkSky is continuously adding more icon types.

class GetWeatherImage
{
    
    func getImage(icon: String) -> UIImage
    {
        switch icon {
        case "clear-day":
            return UIImage(named: "Sunny.png")!
            
        case "clear-night":
            return UIImage(named: "NightMoon.png")!
            
        case "rain":
            return UIImage(named: "Raining.png")!
            
        case "snow":
            return UIImage(named: "OccasionalSnow.png")!
            
        case "sleet":
            return UIImage(named: "Sleet.png")!
            
        case "wind":
            return UIImage(named: "StrongWind.png")!
            
        case "fog":
            return UIImage(named: "Fog.png")!
            
        case "cloudy":
            return UIImage(named: "Overcast.png")!
            
        case "partly-cloudy-day":
            return UIImage(named: "PartlyCloudy.png")!
            
        case "partly-cloudy-night":
            return UIImage(named: "PartlyCloudNight.png")!
            
        default:
            return UIImage(named: "Default.png")!
        }
    }
}
