//
//  WeatherCell.swift
//  Weatherman Kyle
//
//  Created by Kyle Carlos Fernandez on 2019/07/04.
//  Copyright © 2019 Kyle. All rights reserved.
//

import UIKit

class WeatherCell: UICollectionViewCell
{
    // UICollectionViewCell UI
    @IBOutlet var weatherImage: UIImageView!
    @IBOutlet var date: UILabel!
    @IBOutlet var temp: UILabel!
    @IBOutlet var wind: UILabel!
    @IBOutlet var humidity: UILabel!
}

