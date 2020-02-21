//
//  DocSetRelation+CoreDataProperties.swift
//  
//
//  Created by osx on 18/02/20.
//
//

import Foundation
import CoreData


extension DocSetRelation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocSetRelation> {
        return NSFetchRequest<DocSetRelation>(entityName: "DocSetRelation")
    }

    @NSManaged public var index: Int32
    @NSManaged public var docSet: DocSet?
    @NSManaged public var promptDoc: PromptDoc?

}
