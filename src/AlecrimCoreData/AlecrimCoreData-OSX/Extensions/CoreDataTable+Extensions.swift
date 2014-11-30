//
//  CoreDataTable+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-27.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataTable {
    
    public func toArrayController() -> NSArrayController {
        let arrayController = NSArrayController()
        arrayController.managedObjectContext = self.context
        arrayController.entityName = self.underlyingFetchRequest.entityName
        
        if let sortDescriptors = self.underlyingFetchRequest.sortDescriptors {
            arrayController.sortDescriptors = sortDescriptors
        }
        
        if let predicate = self.underlyingFetchRequest.predicate {
            arrayController.fetchPredicate = (predicate.copy() as NSPredicate)
        }
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        
        let defaultFetchRequest = arrayController.defaultFetchRequest()
        defaultFetchRequest.fetchOffset = self.underlyingFetchRequest.fetchOffset
        defaultFetchRequest.fetchLimit = self.underlyingFetchRequest.fetchLimit
        defaultFetchRequest.fetchBatchSize = self.defaultFetchBatchSize
        
        return arrayController
    }
    
}