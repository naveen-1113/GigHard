//
//  DocSet+CoreDataProperties.swift
//  
//
//  Created by osx on 18/02/20.
//
//

import Foundation
import CoreData


extension DocSet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocSet> {
        return NSFetchRequest<DocSet>(entityName: "DocSet")
    }

    @NSManaged public var name: String?
    @NSManaged public var docSetRelation: DocSetRelation?

}
