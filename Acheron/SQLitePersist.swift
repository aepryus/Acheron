//
//  SQLitePersist.swift
//  Acheron
//
//  Created by Joe Charlier on 4/23/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

import Foundation
import SQLite3

public class SQLitePersist: Persist {
	var db: OpaquePointer? = nil
	let queue: DispatchQueue = DispatchQueue(label: "SQLite")

	public override init(_ name: String) {
		
		let path = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]).appendingPathComponent("data")
		
		if !FileManager.default.fileExists(atPath: path.absoluteString) {
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
		
		super.init(name)
		
		createTables()
	}
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
	func unprotectedQuery(_ query: String) -> [[String:Any]] {
		var s: OpaquePointer? = nil
		if sqlite3_prepare_v2(db, query, -1, &s, nil) != SQLITE_OK {
			let error = String(cString: sqlite3_errmsg(db))
			print("\(error)")
		}
		
		var result = [[String:Any]]()
		
		var active = true
		var n = 0
		repeat {
			let sqlret = sqlite3_step(s)
			
			if sqlret == SQLITE_ROW {
				var row = [String:Any]()
				var i: Int32 = 0
				while i < sqlite3_column_count(s) {
					let key = String(validatingUTF8:sqlite3_column_name(s,i))!
					var value: NSObject? = nil
					switch sqlite3_column_type(s,i) {
					case SQLITE_INTEGER:
						value = NSNumber(value: sqlite3_column_int(s,i))
					case SQLITE_TEXT:
						if let chars = UnsafeRawPointer(sqlite3_column_text(s, i)) {
							value = String(validatingUTF8:chars.bindMemory(to: CChar.self, capacity: 0))! as NSString
						}
					default:
						value = nil
					}
					row[key] = value;
					i += 1
				}
				result.append(row)
				
			} else if sqlret == SQLITE_DONE {
				active = false;
				
			} else if sqlret == SQLITE_BUSY {
				n += 1
				if n > 20 {
					logError(message: "SQLite command returned SQLITE_BUSY 20 times")
					active = false
				}
				Thread.sleep(forTimeInterval: 0.1)
				
			} else {
				active = false
			}
			
		} while active;
		
		_ = executeSQLite(sqlite: { () -> (Int32) in
			return sqlite3_finalize(s)
		})
		
		return result;
	}
	private func query(_ query: String) -> [[String:Any]] {
		var result = [[String:Any]]()
		queue.sync {
			result = unprotectedQuery(query)
		}
		return result;
	}
	private func executeSQLite(sqlite: ()->(Int32)) -> Int32 {
		var result: Int32 = 0
		var n = 0
		repeat {
			result = sqlite()
			
			if result == SQLITE_BUSY {
				n += 1
				if n > 20 {
					logError(message: "SQLite command returned SQLITE_BUSY 20 times")
					return result;
				}
				
				Thread.sleep(forTimeInterval: 0.1)
				
			} else if result != SQLITE_OK && result != SQLITE_DONE {
				logError(message: "SQLite command returned with error code [\(result)]")
			}
			
		} while result == SQLITE_BUSY
		
		return result;
	}
	private func execute(_ execute: String) {
		var error: UnsafeMutablePointer<Int8>?
		_ = executeSQLite { () -> (Int32) in
			return sqlite3_exec(db, execute, nil, nil, &error)
		}
		if let error = error {
			print("SQLitePersist: error in database [\(name)] @1\n\texecuting: \(execute)\n\terror: \(error)")
			sqlite3_free(error)
		}
	}
	
// Persist =========================================================================================
	override public func selectAll() -> [[String:Any]] {
		var result = [[String:Any]]()
		let rows = query("SELECT * FROM Document")
		for row in rows {
			let attributes = (row["JSON"] as! String).toAttributes()
			result.append(attributes)
		}
		return result
	}
	override public func selectAll(type: String) -> [[String:Any]] {
		var result = [[String:Any]]()
		let rows = query("SELECT * FROM Document WHERE Type='\(type)'")
		for row in rows {
			let attributes = (row["JSON"] as! String).toAttributes()
			result.append(attributes)
		}
		return result;
	}
	override public func select(where field: String, is value: String?, type: String) -> [[String:Any]] {
		var result = [[String:Any]]()
		let rows = query("SELECT * FROM Document WHERE Type='\(type)'")
		for row in rows {
			let attributes = (row["JSON"] as! String).toAttributes()
			if let rowValue = attributes[field] as? String? {
				if rowValue == value {
					result.append(attributes)
				}
			} else if value == nil {
				result.append(attributes)
			}
		}
		return result
	}
	override public func selectOne(where field: String, is value: String, type: String) -> [String:Any]? {
		let rows = query("SELECT * FROM Document WHERE Type='\(type)'")
		for row in rows {
			let attributes = (row["JSON"] as! String).toAttributes()
			if let rowValue = attributes[field] as? String? {
				if rowValue == value {
					return attributes
				}
			}
		}
		return nil
	}
	
	override public func selectForked() -> [[String:Any]] {
		let fork: Int = Int(get(key: "fork") ?? "0")!
		
		var result = [[String:Any]]()
		let rows = query("SELECT * FROM Document WHERE Fork=\(fork+1)")
		for row in rows {
			let attributes = (row["JSON"] as! String).toAttributes()
			result.append(attributes)
		}
		return result;
	}
	override public func selectForkedMemories() -> [[String:Any]] {
		let fork: Int = Int(get(key: "fork") ?? "0")!
		
		var result = [[String:Any]]()
		let rows = query("SELECT * FROM Memory WHERE Server=1 AND Fork=\(fork+1)")
		for row in rows {
			var attributes = [String:Any]()
			attributes["name"] = row["Name"] as! String
			attributes["value"] = row["Value"] as! String
			attributes["fork"] = row["Fork"] as! Int
			result.append(attributes)
		}
		return result
	}
	
	override public func attributes(iden: String) -> [String:Any]? {
		let rows = query("SELECT * FROM Document WHERE Iden='\(iden)'")
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
	override public func attributes(type: String, only: String) -> [String : Any]? {
		let rows = query("SELECT * FROM Document WHERE Type='\(type)' AND Only='\(only)'")
		guard rows.count < 2 else {fatalError()}
		if rows.count == 0 {return nil}
		do {
			let json: String = rows[0]["JSON"] as! String
			let attributes = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options:[]) as! [String:Any]
			return attributes
		} catch let error as NSError {
			logError(error)
			return nil
		}
	}
	
	override public func delete(iden: String) {
		dispatchPrecondition(condition: .onQueue(queue))
		var s: OpaquePointer? = nil
		_ = executeSQLite(sqlite: { () -> (Int32) in
			return sqlite3_prepare(db, "DELETE FROM Document WHERE Iden='\(iden)'", -1, &s, nil)
		})
		_ = executeSQLite(sqlite: { () -> (Int32) in
			return sqlite3_step(s)
		})
		sqlite3_finalize(s)
	}
	override public func store(iden: String, attributes: [String : Any]) {
		dispatchPrecondition(condition: .onQueue(queue))
		let type = attributes["type"] as! String
		
		var json: String?
		do {
			let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
			json = String(data:data, encoding: .utf8)
		} catch {
			print("\(error)")
			return
		}
		
		let fork: Int32 = attributes["fork"] as! Int32
		
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
			_ = executeSQLite(sqlite: { () -> (Int32) in
				return sqlite3_step(s)
			})
			sqlite3_finalize(s)
		}
	}
	
	override public func transact(_ transact: ()->(Bool)) {
		queue.sync {
			var error: UnsafeMutablePointer<Int8>?
			let result: Int32 = executeSQLite { () -> (Int32) in
				return sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION", nil, nil, &error)
			}
			if result != SQLITE_OK {
				logError(message: "begin transaction failed")
				return;
			}
			
			let shouldCommit = transact()
			
			if shouldCommit {
				_ = executeSQLite(sqlite: { () -> (Int32) in
					return sqlite3_exec(db, "COMMIT TRANSACTION", nil, nil, &error);
				})
			} else {
				_ = executeSQLite(sqlite: { () -> (Int32) in
					return sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, &error);
				})
			}
			
			if let error = error {
				print("SQLitePersist: error in database [\(self.name)] @3\n\terror: \(error)")
				sqlite3_free(error)
				return
			}
		}
	}
	
	override public func wipe() {
		queue.sync {
			dropTables()
			createTables()
		}
	}
	override public func wipeDocuments() {
		queue.sync {
			dropDocument()
			createDocument()
		}
	}
	
	override public func show() {
		print("\nprinting database [\(self.name)]")
		print("===========================================================================")
		
		let documents = selectAll()
		for document in documents {
			print("\(document.toJSON())")
			print("===========================================================================")
		}
		
		print("\n")
	}
	override public func show(_ iden: String) {
		print("===========================================================================")
		print("\(attributes(iden: iden)!)")
	}
	override public func census() {
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
			return sqlite3_prepare(db, "INSERT OR REPLACE INTO Memory (Name, Value, Server, Fork, Gone) VALUES (?, ?, ?, ?, ?)", -1, &s, nil)
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
		let rows = query("SELECT Value FROM Memory WHERE Name = '\(key)'")
		guard rows.count != 0 else {return nil}
		return rows[0]["Value"] as? String
	}
	private func unprotectedGet(key: String) -> String? {
		let rows = unprotectedQuery("SELECT Value FROM Memory WHERE Name = '\(key)'")
		guard rows.count != 0 else {return nil}
		return rows[0]["Value"] as? String
	}
	override open func unset(key: String) {
		queue.sync {
			var s: OpaquePointer? = nil
			_ = executeSQLite(sqlite: { () -> (Int32) in
				return sqlite3_prepare(db, "DELETE FROM Memory WHERE Name='\(key)'", -1, &s, nil)
			})
			_ = executeSQLite(sqlite: { () -> (Int32) in
				return sqlite3_step(s)
			})
			sqlite3_finalize(s)
		}
	}
}
