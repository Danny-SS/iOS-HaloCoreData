//
//  Resource.swift
//
//  This is a utility class to load resouces for testing within our package
//
//  Created by Daniel Murphy on 04/23/2021.
//

import Foundation

class Resource {
  
  let name: String
  let type: String
  
  init(name: String, type: String) {
    self.name = name
    self.type = type
  }
  
  func getDataURL() -> URL? {
    return Bundle.module.url(forResource: name, withExtension: type)
  }
  
  var mockContentData: Data? {
    guard let url = getDataURL(), let data = try? Data(contentsOf: url) else {
        print("Could not get file URL or contents of the url if it exists.  File: \(self.fullName())")
      return nil
    }
    return data
  }
}

extension Resource {
  
  public func fullName() -> String {
    return "\(name).\(type)"
  }
}

