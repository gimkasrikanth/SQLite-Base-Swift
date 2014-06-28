//
//  SQLite.swift
//  SwiftFrameworkTesting
//
//  Created by 招利 李 on 14-6-27.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation
//@asmname("sqlite3_exec") func sqlite3_execute(COpaquePointer,CString,COpaquePointer,AnyObject,COpaquePointer) -> CInt

//结果集
protocol SQLiteRowSet {
    func reset()
    func close()
    func getDictionary() -> Dictionary<String,Any>
    func getUInt(columnName:String) -> UInt!
    func getInt(columnName:String) -> Int!
    func getFloat(columnName:String) -> Float!
    func getDouble(columnName:String) -> Double!
    func getString(columnName:String) -> String!
    func getData(columnName:String) -> NSData!
    func getDate(columnName:String) -> NSDate!
}


//常用
protocol SQLiteUtils {
    //打开并获取数据库接口
    func open() -> (COpaquePointer, NSError?)
    //关闭数据库接口
    func close(handle:COpaquePointer) -> NSError?
    //执行 SQL 语句
    func execute(handle:COpaquePointer, SQL:String) -> NSError?
    //执行 SQL 查询语句
    func query(handle:COpaquePointer, SQL:String) -> SQLiteResultSet?
    //获取最后出错信息
    func lastErrorString(handle:COpaquePointer) -> String
}

//代理
protocol SQLiteDelegate {
    func create(handle:COpaquePointer, sqlite:SQLite)      //<-需要创建所有的表
}

//创建
protocol SQLiteCreate {
    func create(handle:COpaquePointer, tableName:String, params:Dictionary<String, String>, primaryKey:String, autoincrement:Bool) -> NSError?
}

//改变
protocol SQLiteUpdate {
    func update(handle:COpaquePointer, tableName:String, set params:Dictionary<String, Any>, Where:String?) -> NSError?
}

//增加
protocol SQLiteInsert {
    //单条插入
    func insert(handle:COpaquePointer, tableName:String, params:Dictionary<String, Any>) -> NSError?
    
    //批量插入
}

//删除
protocol SQLiteDelete {
    func delete(handle:COpaquePointer, tableName:String, Where:String?) -> NSError?
}

//查询
protocol SQLiteSelect {
    //普通查询
    func select(handle:COpaquePointer, params:String[]?, tableName:String, Where:String?) -> SQLiteResultSet?
    
    //联合查询
    func select(handle:COpaquePointer, params:String[]?, tables:Dictionary<String,String>, Where:String?) -> SQLiteResultSet?
}

//主函数
class SQLite: NSObject {

    let path:String = ""
    let delegate:SQLiteDelegate?
    init(path:String, delegate:SQLiteDelegate!) {
        self.path = path;
        self.delegate = delegate
    }
    init(name:String, delegate:SQLiteDelegate!) {
        let docDir:AnyObject = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        self.path = docDir.stringByAppendingPathComponent(name)
        self.delegate = delegate
    }
    deinit{
    }
    
}

//实用
extension SQLite : SQLiteUtils {
    func open() -> (COpaquePointer, NSError?) {
        var handle:COpaquePointer = nil
        let dbPath:NSString = path

        //如果文件不存在并且代理不为空
        let needCreateTable:Bool = !NSFileManager.defaultManager().fileExistsAtPath(path) && delegate != nil
        
        let result:CInt = sqlite3_open(dbPath.UTF8String, &handle)
        if result != SQLITE_OK {
            sqlite3_close(handle)
            return (handle, NSError(domain: "打开数据库[\(path)]失败", code: Int(result), userInfo: ["path":path]))
        } else {
            delegate!.create(handle)
        }
        return (handle, nil)
    }
    
    func close(handle:COpaquePointer) -> NSError? {
        if handle != nil {
            let result:CInt = sqlite3_close(handle)
            if result != SQLITE_OK {
                NSError(domain: "关闭数据库[\(path)]失败", code: Int(result), userInfo: ["path":path])
            }
        }
        return nil
    }
    func lastErrorString(handle:COpaquePointer) -> String {
        return String.fromCString(sqlite3_errmsg(handle))
    }
    func query(handle:COpaquePointer, SQL:String) -> SQLiteResultSet? {
        println("SQL -> \(SQL)")
        let sql:NSString = SQL
        var stmt:COpaquePointer = nil
        var result:CInt = sqlite3_prepare_v2(handle, sql.UTF8String, -1, &stmt, nil)
        if result != SQLITE_OK {
            sqlite3_finalize(stmt)
            return nil
        }
        return SQLiteResultSet(stmt: stmt);
    }
    func execute(handle:COpaquePointer, SQL:String) -> NSError? {
        println("SQL -> \(SQL)")
        let sql:NSString = SQL
        var stmt:COpaquePointer = nil
        var result:CInt = sqlite3_prepare_v2(handle, sql.UTF8String, -1, &stmt, nil)
        if result != SQLITE_OK {
            sqlite3_finalize(stmt)
            let error = String.fromCString(sqlite3_errmsg(handle))
            return NSError(domain: "EXEC SQL[\(SQL)]ERROR \(error)", code: Int(result), userInfo: ["path":path,"sql":SQL])
        }
        result = sqlite3_step(stmt)
        if result != SQLITE_OK && result != SQLITE_DONE {
            sqlite3_finalize(stmt)
            let error = String.fromCString(sqlite3_errmsg(handle))
            return NSError(domain: "STEP SQL[\(SQL)]ERROR \(error)", code: Int(result), userInfo: ["path":path,"sql":SQL])
        }
        sqlite3_finalize(stmt)
        return nil
    }
}

//创建
extension SQLite : SQLiteCreate {
    func create(handle:COpaquePointer, tableName:String, params:Dictionary<String,String>, primaryKey:String, autoincrement:Bool) -> NSError? {
        var paramString = ""
        var frist:Bool = true
        for (key,value) in params {
            if !frist {
                paramString += ", "
                frist = false
            }
            paramString += "\"\(key)\" \(value)"
            if key == primaryKey {
                paramString += " PRIMARY KEY"
            }
            if autoincrement {
                paramString += " AUTOINCREMENT"
            }
        }
        let sql = "CREATE TABLE IF NOT EXISTS \"\(tableName)\" (\(paramString))"
        return execute(handle, SQL:sql)
    }

}

//更新
extension SQLite : SQLiteUpdate {
    func update(handle:COpaquePointer, tableName:String, set params:Dictionary<String, Any>, Where:String?) -> NSError? {
        var paramString = ""
        var frist:Bool = true
        for (key,value) in params {
            if !frist {
                paramString += " AND "
                frist = false
            }
            paramString += "\"\(key)\" = \"\(value)\""
        }
        if let end = Where {
            paramString += "WHERE \(end)"
        }
        let sql = "UPDATE \(tableName) SET \(paramString)"
        return execute(handle, SQL:sql)
    }
}

//插入
extension SQLite : SQLiteInsert {
    func insert(handle:COpaquePointer, tableName:String, params:Dictionary<String, Any>) -> NSError? {
        let datas:NSDictionary = params
        let keys:NSArray = datas.allKeys
        let values:NSArray = datas.allValues
        let keyString = keys.componentsJoinedByString("\", \"")
        let valueString = values.componentsJoinedByString("\", \"")
        let sql = "INSERT OR REPLACE INTO \(tableName) (\"\(keyString)\") values(\"\(valueString)\")"
        return execute(handle, SQL:sql)
    }
}

//删除
extension SQLite : SQLiteDelete {
    func delete(handle:COpaquePointer, tableName:String, Where:String?) -> NSError? {
        if let end = Where {
            return execute(handle, SQL:"DELETE FROM \(tableName) WHERE \(end)")
        } else {
            return execute(handle, SQL:"DELETE FROM \(tableName)")
        }
    }
}

//查询
extension SQLite : SQLiteSelect {
    //普通查询
    func select(handle:COpaquePointer, params:String[]?, tableName:String, Where:String?) -> SQLiteResultSet? {
        var sql:String = "SELECT "
        if let array:NSArray = params {
            sql += array.componentsJoinedByString(", ")
        } else {
            sql += "*"
        }
        if let end:String = Where {
            sql += " FROM \(tableName) WHERE \(end)"
        } else {
            sql += " FROM \(tableName)"
        }
        return query(handle, SQL: sql)
    }
    
    //联合查询
    func select(handle:COpaquePointer, params:String[]?, tables:Dictionary<String,String>, Where:String?) -> SQLiteResultSet? {
        var sql:String = "SELECT "
        if let array:NSArray = params {
            sql += array.componentsJoinedByString(", ")
        } else {
            sql += "*"
        }
        var paramString = ""
        var frist:Bool = true
        for (key,value) in tables {
            if !frist {
                paramString += ", "
                frist = false
            }
            paramString += "\(value) \(key)"
        }
        if let end:String = Where {
            sql += " FROM \(paramString) WHERE \(end)"
        } else {
            sql += " FROM \(paramString)"
        }
        return query(handle, SQL: sql)
    }
}

class SQLiteResultSet: NSObject {
    let stmt:COpaquePointer = nil
    let columnCount:Int = 0
    let columnNames:NSArray
    init (stmt:COpaquePointer) {
        self.stmt = stmt
        let length = sqlite3_column_count(stmt);
        var columns:String[] = []
        columnCount = Int(length)
        for i:CInt in 0..length {
            let name:CString = sqlite3_column_name(stmt,i)
            columns += String.fromCString(name)
        }
        columnNames = columns
    }
    deinit {
        if stmt {
            sqlite3_finalize(stmt)
        }
    }
    
    var next:Bool {
    get {
        return sqlite3_step(stmt) == SQLITE_ROW
    }
    }
    var row:Int {
    get {
        return Int(sqlite3_data_count(stmt))
    }
    }
}

extension SQLiteResultSet : SQLiteRowSet {
    
    func reset() {
        sqlite3_reset(stmt)
    }
    func close() {
        sqlite3_finalize(stmt)
    }
    func getDictionary() -> Dictionary<String, Any> {
        var dict:Dictionary<String, Any> = [:]
        for i in 0..columnNames.count {
            let index = CInt(i)
            let type = sqlite3_column_type(stmt, index);
            let key:String = columnNames[i] as String
            switch type {
            case SQLITE_INTEGER:
                dict[key] = Int(sqlite3_column_int(stmt, index))
            case SQLITE_FLOAT:
                dict[key] = Float(sqlite3_column_double(stmt, index))
            case SQLITE_TEXT:
                dict[key] = String.fromCString(CString(sqlite3_column_text(stmt, index)))
            case SQLITE_BLOB:
                let data:CConstVoidPointer = sqlite3_column_blob(stmt, index)
                let size:CInt = sqlite3_column_bytes(stmt, index)
                dict[key] = NSData(bytes:data, length: Int(size))
            case SQLITE_NULL:
                fallthrough     //下降关键字 执行下一 CASE
            default :
                break           //什么都不执行
            }
        }
        
        return dict
    }
    func getUInt(columnName:String) -> UInt! {
        return UInt(getInt(columnName))
    }
    func getInt(columnName:String) -> Int! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        return Int(sqlite3_column_int(stmt, index))
    }
    func getDouble(columnName:String) -> Double! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        return Double(sqlite3_column_double(stmt, index))
    }
    func getFloat(columnName:String) -> Float! {
        return Float(getDouble(columnName))
    }
    func getString(columnName:String) -> String! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        let result:CString = CString(sqlite3_column_text(stmt, index))
        return String.fromCString(result)
    }
    func getData(columnName:String) -> NSData! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        let data:CConstVoidPointer = sqlite3_column_blob(stmt, index)
        let size:CInt = sqlite3_column_bytes(stmt, index)
        return NSData(bytes:data, length: Int(size))
    }
    func getDate(columnName:String) -> NSDate! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        let result:CString = CString(sqlite3_column_text(stmt, index))
        let date:NSString = String.fromCString(result)
        let format = NSDateFormatter(dateFormat: "yyyy-MM-dd HH:mm:ss", allowNaturalLanguage: true)
        return format.dateFromString(date)
    }
}
