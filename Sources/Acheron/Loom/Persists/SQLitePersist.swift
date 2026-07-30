//
//  SQLitePersist.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if !os(Linux)

import Foundation
import SQLite3

public class SQLitePersist: Persist {
    var db: OpaquePointer? = nil
    let queue: DispatchQueue = DispatchQueue(label: "SQLite")

    public convenience override init(_ name: String) {
        self.init(name, directory: (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).appendingPathComponent("data"))
    }
    public init(_ name: String, directory: URL) {

        let path = directory

        if !FileManager.default.fileExists(atPath: path.path) {
            do {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
            } catch  {
                print("\(error)")
            }
        }
        
        let database = path.appendingPathComponent("\(name).sql")
        
        print("opening [\(name).sql]")
        
        if sqlite3_open_v2(database.path, &db, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            print("\(error)")
        }
        sqlite3_busy_timeout(db, 2000)

        super.init(name)

        execute("PRAGMA journal_mode=WAL")
        createTables()
    }
    deinit { sqlite3_close(db) }
    private func createDocument() {
        execute("CREATE TABLE IF NOT EXISTS Document (Iden TEXT PRIMARY KEY, Type TEXT, Only TEXT, JSON TEXT, Fork INTEGER)")
        execute("CREATE INDEX IF NOT EXISTS DocumentType ON Document (Type)")
        execute("CREATE INDEX IF NOT EXISTS DocumentFork ON Document (Fork)")
        execute("CREATE INDEX IF NOT EXISTS DocumentOnly ON Document (Type, Only)")
    }
    private func dropDocument() {
        execute("DROP TABLE Document")
    }
    private func createTables() {
        createDocument()
        execute("CREATE TABLE IF NOT EXISTS Memory (Name TEXT, Value TEXT, Server INTEGER, Vers INTEGER, Fork INTEGER, Gone INTEGER, PRIMARY KEY (Name))")
    }
    private func dropTables() {
        dropDocument()
        execute("DROP TABLE Memory")
    }
    
// Private =========================================================================================
    func unprotectedQuery(_ query: String, _ params: [Any] = []) -> [[String:Any]] {
        var s: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, query, -1, &s, nil) != SQLITE_OK {
            logError(message: "prepare failed [\(String(cString: sqlite3_errmsg(db)))] in [\(query)]")
            return []
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (i, param) in params.enumerated() {
            switch param {
                case let value as Int:    _ = sqlite3_bind_int64(s, Int32(i+1), Int64(value))
                case let value as Double: _ = sqlite3_bind_double(s, Int32(i+1), value)
                case let value as String: _ = sqlite3_bind_text(s, Int32(i+1), value, -1, SQLITE_TRANSIENT)
                default:                  _ = sqlite3_bind_null(s, Int32(i+1))
            }
        }

        var result: [[String:Any]] = []
        while true {
            let sqlret = sqlite3_step(s)
            if sqlret == SQLITE_ROW {
                var row: [String:Any] = [:]
                for i in 0..<sqlite3_column_count(s) {
                    let key = String(validatingUTF8: sqlite3_column_name(s,i))!
                    switch sqlite3_column_type(s,i) {
                        case SQLITE_INTEGER: row[key] = NSNumber(value: sqlite3_column_int64(s,i))
                        case SQLITE_FLOAT:   row[key] = NSNumber(value: sqlite3_column_double(s,i))
                        case SQLITE_TEXT:    row[key] = String(cString: sqlite3_column_text(s,i)) as NSString
                        default:             break
                    }
                }
                result.append(row)
            } else {
                if sqlret != SQLITE_DONE { logError(message: "step returned [\(sqlret)] in [\(query)]") }
                break
            }
        }

        sqlite3_finalize(s)
        return result
    }
    private func query(_ query: String, _ params: [Any] = []) -> [[String:Any]] {
        var result: [[String:Any]] = []
        queue.sync {
            result = unprotectedQuery(query, params)
        }
        return result;
    }
    private func documents(_ sql: String, _ params: [Any] = []) -> [[String:Any]] {
        query(sql, params).map { ($0["JSON"] as! String).toAttributes() }
    }
    private func expand(_ clause: String) -> String {
        clause.replacingOccurrences(of: "\\$(\\w+)", with: "json_extract(JSON,'$.$1')", options: .regularExpression)
    }
    private func executeSQLite(sqlite: ()->(Int32)) -> Int32 {
        let result: Int32 = sqlite()
        if result != SQLITE_OK && result != SQLITE_DONE {
            logError(message: "SQLite command returned with error code [\(result)]")
        }
        return result
    }
    private func execute(_ execute: String) {
        var error: UnsafeMutablePointer<Int8>?
        _ = executeSQLite { () -> (Int32) in
            return sqlite3_exec(db, execute, nil, nil, &error)
        }
        if let error = error {
            print("SQLitePersist: error in database [\(name)] @1\n\texecuting: \(execute)\n\terror: \(String(cString: error))")
            sqlite3_free(error)
        }
    }
    
// Persist =========================================================================================
    public override func selectAll() -> [[String:Any]] {
        documents("SELECT JSON FROM Document")
    }
    public override func selectAll(type: String) -> [[String:Any]] {
        documents("SELECT JSON FROM Document WHERE Type=?", [type])
    }
    private func clean(_ name: String) -> Bool { !name.isEmpty && name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" } }

    public override func select(where field: String, is value: String?, type: String) -> [[String:Any]] {
        guard clean(field) else { logError(message: "select: field '\(field)' has characters outside [A-Za-z0-9_]; no rows returned"); return [] }
        return documents("SELECT JSON FROM Document WHERE Type=? AND json_extract(JSON,'$.\(field)') IS ?", [type, value as Any? ?? NSNull()])
    }
    public override func selectOne(where field: String, is value: String, type: String) -> [String:Any]? {
        guard clean(field) else { logError(message: "selectOne: field '\(field)' has characters outside [A-Za-z0-9_]; no rows returned"); return nil }
        return documents("SELECT JSON FROM Document WHERE Type=? AND json_extract(JSON,'$.\(field)')=? LIMIT 1", [type, value]).first
    }
    public override func index(type: String, field: String) {
        guard clean(type), clean(field) else {
            logError(message: "index: type '\(type)' or field '\(field)' has characters outside [A-Za-z0-9_]; no index created")
            return
        }
        execute("CREATE INDEX IF NOT EXISTS Document_\(type)_\(field) ON Document (Type, json_extract(JSON,'$.\(field)'))")
    }
    private func glued(_ clause: String) -> String {
        let expanded = expand(clause).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expanded.isEmpty else { return "" }
        let upper = expanded.uppercased()
        let bare = upper.hasPrefix("ORDER") || upper.hasPrefix("LIMIT") || upper.hasPrefix("GROUP")
        return (bare ? " " : " AND ") + expanded
    }

    public override func select(type: String, where clause: String, params: [Any]) -> [[String:Any]] {
        documents("SELECT JSON FROM Document WHERE Type=?" + glued(clause), [type] + params)
    }
    public override func count(type: String, where clause: String, params: [Any]) -> Int {
        (query("SELECT COUNT(*) AS n FROM Document WHERE Type=?" + glued(clause), [type] + params).first?["n"] as? NSNumber)?.intValue ?? 0
    }

    public override func selectForked() -> [[String:Any]] {
        let fork: Int = Int(get(key: "fork") ?? "0") ?? 0
        return documents("SELECT JSON FROM Document WHERE Fork=?", [fork+1])
    }
    public override func selectForkedMemories() -> [[String:Any]] {
        let fork: Int = Int(get(key: "fork") ?? "0") ?? 0

        var result: [[String:Any]] = []
        let rows = query("SELECT * FROM Memory WHERE Server=1 AND Fork=?", [fork+1])
        for row in rows {
            var attributes = [String:Any]()
            attributes["name"] = row["Name"] as! String
            attributes["value"] = row["Value"] as! String
            attributes["fork"] = row["Fork"] as! Int
            result.append(attributes)
        }
        return result
    }
    
    public override func attributes(iden: String) -> [String:Any]? {
        let rows = query("SELECT * FROM Document WHERE Iden=?", [iden])
        if rows.count != 1 {return nil}
        do {
            let json: String = rows[0]["JSON"] as! String
            let attributes = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options:[]) as! [String:Any]
            return attributes
        } catch let error as NSError {
            logError(error)
            return nil
        }
    }
    public override func attributes(type: String, only: String) -> [String : Any]? {
        let rows = query("SELECT * FROM Document WHERE Type=? AND Only=?", [type, only])
        if rows.count > 1 {
            logError(message: "SQLitePersist: duplicate Document rows for Type=\(type) Only=\(only) (count=\(rows.count)); using first row")
        }
        if rows.count == 0 { return nil }
        do {
            let json: String = rows[0]["JSON"] as! String
            let attributes = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [String: Any]
            return attributes
        } catch let error as NSError {
            logError(error)
            return nil  
        }
    }

    /// Deletes extra `Document` rows that share the same `Type` and `Only` (keeps lexicographically smallest `Iden`). Use after historic duplicates (e.g. folder rows).
    public override func deduplicateDocumentsWithSharedOnlyKey(type: String) {
        queue.sync {
            let rows = unprotectedQuery("SELECT Iden, Only FROM Document WHERE Type=? AND Only IS NOT NULL", [type])
            var byOnly: [String: [String]] = [:]
            for row in rows {
                guard let iden = row["Iden"] as? String,
                      let only = row["Only"] as? String,
                      !only.isEmpty else { continue }
                byOnly[only, default: []].append(iden)
            }
            for (_, idens) in byOnly where idens.count > 1 {
                let sorted = idens.sorted()
                guard let keep = sorted.first else { continue }
                for iden in sorted where iden != keep {
                    delete(iden: iden)
                }
            }
        }
    }
    
    @discardableResult public override func delete(iden: String) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))
        var s: OpaquePointer? = nil
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_prepare(db, "DELETE FROM Document WHERE Iden=?", -1, &s, nil)
        })
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_text(s, 1, iden, -1, SQLITE_TRANSIENT)
        })
        let result = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_step(s)
        })
        sqlite3_finalize(s)
        return result == SQLITE_DONE
    }
    @discardableResult public override func store(iden: String, attributes: [String : Any]) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let type = attributes["type"] as? String else {
            logError(message: "store: document \(iden) has no type; row skipped")
            return true
        }

        // A poisoned document must not dam the batch: log loudly, drop the row, commit the rest.
        guard JSONSerialization.isValidJSONObject(attributes) else {
            logError(message: "store: [\(type)] \(iden) is not JSON-encodable (NaN/Infinity or a non-plist value in its attributes); row skipped, prior version retained")
            return true
        }

        var json: String?
        do {
            let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
            json = String(data:data, encoding: .utf8)
        } catch {
            logError(message: "store: [\(type)] \(iden) failed to serialize; row skipped, prior version retained")
            logError(error)
            return true
        }

        let fork: Int32 = (attributes["fork"] as? NSNumber)?.int32Value ?? 0

        var result: Int32 = SQLITE_DONE
        if let json = json {
            var s: OpaquePointer? = nil
            
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_prepare(db, "INSERT OR REPLACE INTO Document (Iden, Type, Only, JSON, Fork) VALUES (?, ?, ?, ?, ?)", -1, &s, nil)
            })
            
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_bind_text(s, 1, iden, -1, SQLITE_TRANSIENT)
            })
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_bind_text(s, 2, type, -1, SQLITE_TRANSIENT)
            })
            
            if let key = typeToOnly[type], let only = attributes[key] {
                _ = executeSQLite(sqlite: { () -> (Int32) in
                    return sqlite3_bind_text(s, 3, "\(only)", -1, SQLITE_TRANSIENT)
                })
            } else {
                _ = executeSQLite(sqlite: { () -> (Int32) in
                    return sqlite3_bind_null(s, 3)
                })
            }

            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_bind_text(s, 4, json, -1, SQLITE_TRANSIENT)
            })

            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_bind_int(s, 5, fork)
            })
            result = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_step(s)
            })
            sqlite3_finalize(s)
        }
        return result == SQLITE_DONE
    }

    @discardableResult public override func transact(_ transact: ()->(Bool)) -> Bool {
        queue.sync {
            var error: UnsafeMutablePointer<Int8>?
            let result: Int32 = executeSQLite { () -> (Int32) in
                return sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION", nil, nil, &error)
            }
            if result != SQLITE_OK {
                logError(message: "begin transaction failed")
                return false
            }

            let shouldCommit = transact()

            let finish: Int32 = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_exec(db, shouldCommit ? "COMMIT TRANSACTION" : "ROLLBACK TRANSACTION", nil, nil, &error);
            })

            if let error = error {
                print("SQLitePersist: error in database [\(self.name)] @3\n\terror: \(String(cString: error))")
                sqlite3_free(error)
            }
            return shouldCommit && finish == SQLITE_OK
        }
    }
    
    public override func wipe() {
        queue.sync {
            dropTables()
            createTables()
        }
    }
    public override func wipeDocuments() {
        queue.sync {
            dropDocument()
            createDocument()
        }
    }
    
    public override func show() {
        print("\nprinting database [\(self.name)]")
        print("===========================================================================")
        
        let documents = selectAll()
        for document in documents {
            print("\(document.toJSON())")
            print("===========================================================================")
        }
        
        print("\n")
    }
    public override func show(_ iden: String) {
        print("===========================================================================")
        print("\(attributes(iden: iden) ?? [:])")
    }
    public override func census() {
        print("\nprinting census [\(self.name)]")
        print("===========================================================================")
        
        let documents = selectAll()
        var census: [String:Int] = [:]
        documents.forEach {
            let type: String = $0["type"] as! String
            if census[type] == nil {census[type] = 0}
            census[type] = census[type]! + 1
        }
        
        for (type,count) in census {
            print("\t\(type):\(count)")
        }
        
        print("\n")
    }
    
    private func set(key: String, value: String, server: Bool) {
        let fork: Int32 = Int32(unprotectedGet(key: "fork") ?? "0")! + 1
        var s: OpaquePointer? = nil
        
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_prepare(db, "INSERT OR REPLACE INTO Memory (Name, Value, Server, Vers, Fork, Gone) VALUES (?, ?, ?, ?, ?, ?)", -1, &s, nil)
        })
        
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_text(s, 1, key, -1, SQLITE_TRANSIENT)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_text(s, 2, value, -1, SQLITE_TRANSIENT)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_int(s, 3, server ? 1 : 0)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_int(s, 4, fork)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_int(s, 5, fork)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_bind_int(s, 6, 0)
        })
        _ = executeSQLite(sqlite: { () -> (Int32) in
            return sqlite3_step(s)
        })
        sqlite3_finalize(s)
    }
    override open func set(key: String, value: String) {
        queue.sync {
            set(key: key, value: value, server: false)
        }
    }
    override open func setServer(key: String, value: String) {
        queue.sync {
            set(key: key, value: value, server: true)
        }
    }
    override open func get(key: String) -> String? {
        let rows = query("SELECT Value FROM Memory WHERE Name=?", [key])
        guard rows.count != 0 else {return nil}
        return rows[0]["Value"] as? String
    }
    private func unprotectedGet(key: String) -> String? {
        let rows = unprotectedQuery("SELECT Value FROM Memory WHERE Name=?", [key])
        guard rows.count != 0 else {return nil}
        return rows[0]["Value"] as? String
    }
    override open func unset(key: String) {
        queue.sync {
            var s: OpaquePointer? = nil
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_prepare(db, "DELETE FROM Memory WHERE Name=?", -1, &s, nil)
            })
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_bind_text(s, 1, key, -1, SQLITE_TRANSIENT)
            })
            _ = executeSQLite(sqlite: { () -> (Int32) in
                return sqlite3_step(s)
            })
            sqlite3_finalize(s)
        }
    }
}

#endif
