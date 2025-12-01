//
//  KeychainStorage.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 26/10/25.
//

import Foundation
import Security

final class KeychainStorage: SecureStorageProtocol {
    private let serviceName: String
    
    init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.promentorhq") {
        self.serviceName = serviceName
    }
    
    func save(value: String, forKey key: String) throws -> Void {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.stringConversionFailed
        }
        
        let query = createBaseQuery(forKey: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            if updateStatus != errSecSuccess {
                throw KeychainError.updateFailed(status)
            }
        } else if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            if addStatus != errSecSuccess {
                throw KeychainError.saveFailed(addStatus)
            }
        } else {
            throw KeychainError.unknown(status)
        }
    }
    
    func get(forKey key: String) throws -> String? {
        var query = createBaseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            guard let data = result as? Data,
                  let stringValue = String(data: data, encoding: .utf8)
            else {
                throw KeychainError.dataConversionFailed
            }
            
            return stringValue
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.fetchFailed(status)
        }
    }
    
    func delete(forKey key: String) throws -> Void {
        let query = createBaseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    func deleteAll() throws -> Void {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    private func createBaseQuery(forKey key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
    
    enum KeychainError: Error {
        case stringConversionFailed
        case dataConversionFailed
        case saveFailed(OSStatus)
        case updateFailed(OSStatus)
        case fetchFailed(OSStatus)
        case deleteFailed(OSStatus)
        case unknown(OSStatus)
    }
}
