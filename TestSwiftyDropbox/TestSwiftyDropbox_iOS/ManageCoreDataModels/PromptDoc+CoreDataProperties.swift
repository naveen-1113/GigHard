//
//  PromptDoc+CoreDataProperties.swift
//  
//
//  Created by osx on 18/02/20.
//
//

import Foundation
import CoreData


extension PromptDoc {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PromptDoc> {
        return NSFetchRequest<PromptDoc>(entityName: "PromptDoc")
    }

    @NSManaged public var docAttText: NSAttributedString?
    @NSManaged public var docText: String?
    @NSManaged public var docTitle: String?
    @NSManaged public var editTextSize: Int16
    @NSManaged public var proptSpeed: Int16
    @NSManaged public var promptTextSize: Int16
    @NSManaged public var updateDate: Date?
    @NSManaged public var docFont: CustomFont?
    @NSManaged public var docSetRelation: DocSetRelation?

}
