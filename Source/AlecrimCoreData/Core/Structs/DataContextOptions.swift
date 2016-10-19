//
//  DataContextOptions.swift
//  Pods
//
//  Created by Vithorio Polten on 19/10/16.
//
//

import Foundation
import CoreData

public enum StoreType {
    case SQLite
    case InMemory
}

public struct DataContextOptions {
    
    // MARK: - options valid for all instances
    
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonPredicateOptions: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]
    
    @available(*, unavailable, renamed: "defaultBatchSize")
    public static var batchSize: Int = 20
    
    @available(*, unavailable, renamed: "defaultComparisonPredicateOptions")
    public static var stringComparisonPredicateOptions: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]
    
    // MARK: -
    
    public let managedObjectModelURL: NSURL?
    public let persistentStoreURL: NSURL?
    
    // MARK: -
    
    public var storeType: StoreType = .SQLite
    public var configuration: String? = nil
    public var options: [String : Any] = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    
    // MARK: - THE constructor
    
    public init(managedObjectModelURL: NSURL, persistentStoreURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = persistentStoreURL
    }
    
    // MARK: - "convenience" initializers
    
    public init(managedObjectModelURL: NSURL) throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    public init(persistentStoreURL: NSURL) throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() throws {
        let mainBundle = Bundle.main
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    // MARK: -
    
    public init(managedObjectModelBundle: Bundle, managedObjectModelName: String, bundleIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURL(forManagedObjectModelName: managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURL(forManagedObjectModelName: managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
    /// Initializes ContextOptions with properties filled for use by main app and its extensions.
    ///
    /// - parameter managedObjectModelBundle:   The managed object model bundle. You can use `NSBundle(forClass: MyModule.MyDataContext.self)`, for example.
    /// - parameter managedObjectModelName:     The managed object model name without the extension. Example: `"MyGreatApp"`.
    /// - parameter bundleIdentifier:           The bundle identifier for use when creating the directory for the persisent store. Example: `"com.mycompany.MyGreatApp"`.
    /// - parameter applicationGroupIdentifier: The application group identifier (see Xcode target settings). Example: `"group.com.mycompany.MyGreatApp"` for iOS or `"12ABCD3EF4.com.mycompany.MyGreatApp"` for OS X where `12ABCD3EF4` is your team identifier.
    ///
    /// - returns: An initialized ContextOptions with properties filled for use by main app and its extensions.
    public init(managedObjectModelBundle: Bundle, managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURL(forManagedObjectModelName: managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURL(forManagedObjectModelName: managedObjectModelName, bundleIdentifier: bundleIdentifier, applicationGroupIdentifier: applicationGroupIdentifier)
    }
    
}

// MARK: - Ubiquity (iCloud) helpers

extension DataContextOptions {
    
    #if os(OSX) || os(iOS)
    
    public var ubiquityEnabled: Bool {
        return self.storeType == .SQLite && self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public mutating func configureUbiquityWithContainerIdentifier(containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] = containerIdentifier
        self.options[NSPersistentStoreUbiquitousContentURLKey] = contentRelativePath
        self.options[NSPersistentStoreUbiquitousContentNameKey] = contentName
        
        self.options[NSMigratePersistentStoresAutomaticallyOption] = true
        self.options[NSInferMappingModelAutomaticallyOption] = true
    }
    
    #endif
}


// MARK: - private NSBundle extensions

extension Bundle {
    
    /// This variable is used to guess a managedObjectModelName.
    /// The provided kCFBundleNameKey we are using to determine the name will include spaces, whereas managed object model name uses underscores in place of spaces by default - hence why we are replacing " " with "_" here
    fileprivate var inferredManagedObjectModelName: String? {
        return (self.infoDictionary?[String(kCFBundleNameKey)] as? String)?.replacingOccurrences(of: " ", with: "_")
    }
    
}

extension Bundle {
    
    fileprivate func defaultManagedObjectModelURL() throws -> NSURL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName else {
            throw AlecrimCoreDataError.unexpectedValue("InvalidManagedObjectModelURL")
        }
        
        return try self.managedObjectModelURL(forManagedObjectModelName: managedObjectModelName)
    }
    
    fileprivate func defaultPersistentStoreURL() throws -> NSURL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName, let bundleIdentifier = self.bundleIdentifier else {
            throw AlecrimCoreDataError.unexpectedValue("InvalidPersistentStoreURL")
        }
        
        return try self.persistentStoreURL(forManagedObjectModelName: managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
}

extension Bundle {
    
    fileprivate func managedObjectModelURL(forManagedObjectModelName name: String) throws -> NSURL {
        guard let url = self.url(forResource: name, withExtension: "momd") else {
            throw AlecrimCoreDataError.unexpectedValue("InvalidManagedObjectModelURL")
        }
        
        return url as NSURL
    }
    
    fileprivate func persistentStoreURL(forManagedObjectModelName name: String, bundleIdentifier: String) throws -> NSURL {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            throw AlecrimCoreDataError.unexpectedValue("InvalidPersistentStoreURL")
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((name as NSString)
                .appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url as NSURL
    }
    
    fileprivate func persistentStoreURL(forManagedObjectModelName name: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws -> NSURL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw AlecrimCoreDataError.unexpectedValue("InvalidPersistentStoreURL")
        }
        
        let url = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((name as NSString)
                .appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url as NSURL
    }
    
}

// MARK: -

@available(*, unavailable, renamed: "DataContextOptions")
public struct ContextOptions {
    
}
