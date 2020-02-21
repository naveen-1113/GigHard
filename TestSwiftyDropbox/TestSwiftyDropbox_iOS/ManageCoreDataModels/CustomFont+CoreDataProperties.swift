//
//  CustomFont+CoreDataProperties.swift
//  
//
//  Created by osx on 18/02/20.
//
//

import Foundation
import CoreData


extension CustomFont {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomFont> {
        return NSFetchRequest<CustomFont>(entityName: "CustomFont")
    }

    @NSManaged public var systemName: String?
    @NSManaged public var displayName: String?
    @NSManaged public var docs: PromptDoc?

}
