//
//  NSManagedObjectContext+Setup.swift
//  HardcoreData
//
//  Copyright (c) 2015 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CoreData


// MARK: - NSManagedObjectContext

internal extension NSManagedObjectContext {
    
    // MARK: Internal
    
    internal weak var parentStack: DataStack? {
        
        get {
            
            if let parentContext = self.parentContext {
                
                return parentContext.parentStack
            }
            
            return self.getAssociatedObjectForKey(&PropertyKeys.parentStack)
        }
        set {
            
            if self.parentContext != nil {
                
                return
            }
            
            self.setAssociatedWeakObject(
                newValue,
                forKey: &PropertyKeys.parentStack)
        }
    }
    
    internal class func rootSavingContextForCoordinator(coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        context.setupForHardcoreDataWithContextName("com.hardcoredata.rootcontext")
        
        return context
    }
    
    internal class func mainContextForRootContext(rootContext: NSManagedObjectContext) -> NSManagedObjectContext {
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = rootContext
        context.setupForHardcoreDataWithContextName("com.hardcoredata.maincontext")
        context.shouldCascadeSavesToParent = true
        context.undoManager = nil
        context.observerForDidSaveNotification = NotificationObserver(
            notificationName: NSManagedObjectContextDidSaveNotification,
            object: rootContext,
            closure: { [weak context] (note) -> Void in
                
                context?.performBlockAndWait { () -> Void in
                    
                    context?.mergeChangesFromContextDidSaveNotification(note)
                }
                return
            }
        )
        
        return context
    }
    
    
    // MARK: Private
    
    private struct PropertyKeys {
        
        static var parentStack: Void?
        static var observerForDidSaveNotification: Void?
    }
    
    private var observerForDidSaveNotification: NotificationObserver? {
        
        get {
            
            return self.getAssociatedObjectForKey(&PropertyKeys.observerForDidSaveNotification)
        }
        set {
            
            self.setAssociatedRetainedObject(
                newValue,
                forKey: &PropertyKeys.observerForDidSaveNotification)
        }
    }
}