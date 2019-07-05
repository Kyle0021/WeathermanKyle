//
//  RestDelegate.swift
//  Weatherman Kyle
//
//  Created by Kyle Carlos Fernandez on 2019/07/03.
//  Copyright © 2019 Kyle. All rights reserved.
//

import Foundation

protocol RestDelegate
{
    func onPostExecute(_ response: NSDictionary)
}
