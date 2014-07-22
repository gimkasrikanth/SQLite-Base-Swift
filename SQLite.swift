//
//  SQLite.swift
//  SwiftFrameworkTesting
//
//  Created by 招利 李 on 14-6-27.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//
//  引用 libsqlite.3.0.dylib
//  需要建立 ProjectName-Bridging-Header.h 桥文件,并写下 #import "sqlite3.h"
//
//  使用例子如下 : (OS X 开发也可以用)
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    extension ViewController : SQLiteDelegate {
//        func create(handle:COpaquePointer, sqlite:SQLite) {
//            //创建电脑表
//            sqlite.create(handle,
//                tableName: "Computer",
//                params:    [.SQL_Int    ("cid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("brand",.SQL_NotNull),
//                            .SQL_Int    ("cpu", .SQL_NotNull)])
//            //创建处理器表
//            sqlite.create(handle,
//                tableName: "CPU",
//                params:    [.SQL_Int    ("uid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("firm",.SQL_NotNull)])
//            //创建使用者表
//            sqlite.create(handle,
//                tableName: "Preson",
//                params:    [.SQL_Int    ("pid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("name",.SQL_NotNull),
//                            .SQL_Int    ("computer",.SQL_Default)])
//            
//            sqlite.insert(handle, tableName: "CPU", params:["firm":"AMD"])
//            sqlite.insert(handle, tableName: "CPU", params:["firm":"Intel"])
//            
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Apple", "cpu":2])
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Hp", "cpu":1])
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Dell", "cpu":2])
//            
//            sqlite.insert(handle, tableName: "Preson", params:["name":"lzl", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"lc", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"jc", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"gd", "computer":2])
//            
//            println("插入完成")
//            
//        }
//    }
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  在需要查询的时候代码如下
//
//  let sqlite = SQLite(path:"/Users/apple/Documents/test.sqlite",delegate:self)
//
//  let (handle,_) = sqlite.open()
//  let count = sqlite.count(handle,tableName: "Preson", Where: "computer = 1")
//  println("有苹果电脑的人数为\(count)")
//
//  //查询所有电脑品牌为 Apple的数据
//  if let rs = sqlite.select(handle,params:nil, tables: ["p":"Preson","cp":"Computer","c":"CPU"], Where: "p.computer = cp.cid AND cp.cpu = c.uid AND p.computer = 1") {
//      println("查询成功")
//      while rs.next {
//          let dict = rs.getDictionary()
//          println("data:\(dict)")
//      }
//    
//  } else {
//      println("查询失败")
//  }
//


@asmname("sqlite3_exec") func sqlite3_execute(COpaquePointer,ConstUnsafePointer<CChar>,CFunctionPointer<Void>,COpaquePointer,AutoreleasingUnsafePointer<ConstUnsafePointer<CChar>>) -> CInt
@asmname("sqlite3_bind_blob") func sqlite3_bind_data(COpaquePointer,CInt,ConstUnsafePointer<()>,CInt,COpaquePointer) -> CInt
@asmname("sqlite3_bind_text") func sqlite3_bind_string(COpaquePointer,CInt,ConstUnsafePointer<CChar>,CInt,COpaquePointer) -> CInt
//@asmname("sqlite3_column_table_name") func sqlite3_column_table_title(COpaquePointer,CInt) -> CString
//sqlite3_column_table_name
import Foundation

//结果集
protocol SQLiteRowSet {
    func reset()
    func close()
    func getDictionary() -> [String:Any]
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
    //打开并获取数据库句柄
    func open() -> (COpaquePointer, NSError?)
    //关闭数据库句柄
    func close(handle:COpaquePointer) -> NSError?
    //执行 SQL 语句
    func execute(handle:COpaquePointer, SQL:String) -> NSError?
    //执行 SQL 查询语句
    func query(handle:COpaquePointer, SQL:String) -> SQLite.ResultSet?
    //获取最后出错信息
    func lastErrorString(handle:COpaquePointer) -> String!
}

//代理 @objc 表示可选
@objc protocol SQLiteDelegate {
    optional func create(handle:COpaquePointer, sqlite:SQLite)      //<-需要创建所有的表
    optional func log(log:String)
//    @optional func error(log:String)
}

//创建
protocol SQLiteCreate {

    func create(handle:COpaquePointer, tableName:String, params:[SQLite.ColumnHeader]) -> NSError?
    
    func create(handle:COpaquePointer, tableName:String, params:[String:String], primaryKey:String, autoincrement:Bool) -> NSError?
}

//改变
protocol SQLiteUpdate {
    func update(handle:COpaquePointer, tableName:String, set params:[String:Any], Where:String?) -> NSError?
}

//增加
protocol SQLiteInsert {
    //单条插入
    func insert(handle:COpaquePointer, tableName:String, params:[String:Any]) -> NSError?
    
    //批量插入 (也可以单条 推荐)
    func insert(handle:COpaquePointer, tableName:String, columnNames:[String], columnValueFactory:(Int)->[SQLite.ColumnValue]?) -> NSError?
    func insert(handle:COpaquePointer, tableName:String, params:[SQLite.ColumnValue]) -> NSError?
}

//删除
protocol SQLiteDelete {
    func delete(handle:COpaquePointer, tableName:String, Where:String?) -> NSError?
}

//查询
protocol SQLiteSelect {
    //查询数量
    func count(handle:COpaquePointer, tableName:String, Where:String?) -> Int
    
    //普通查询
    func select(handle:COpaquePointer, params:[String]?, tableName:String, Where:String?) -> SQLite.ResultSet?
    
    //联合查询
    func select(handle:COpaquePointer, params:[String]?, tables:[String:String], Where:String?) -> SQLite.ResultSet?
}

//主函数
class SQLite: NSObject {

    let path:String = ""
    let delegate:SQLiteDelegate?
    init(path:String, delegate:SQLiteDelegate!) {
        self.path = path;
        self.delegate = delegate
    }
    //适合 iOS
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
        var needCreateTable:Bool = false
        if let sqlDelegate = delegate {
            needCreateTable = !NSFileManager.defaultManager().fileExistsAtPath(path)
        }
        
        let result:CInt = sqlite3_open(dbPath.UTF8String, &handle)
        if result != SQLITE_OK {
            sqlite3_close(handle)
            return (handle, NSError(domain: "打开数据库[\(path)]失败", code: Int(result), userInfo: ["path":path]))
        } else if needCreateTable {
            delegate?.create?(handle, sqlite:self)
        } else {
            //assert(delegate == nil, message: "打开数据库[\(path)]失败")
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
    func lastErrorString(handle:COpaquePointer) -> String! {
        return String.fromCString(sqlite3_errmsg(handle))
    }
    func query(handle:COpaquePointer, SQL:String) -> SQLite.ResultSet? {
        delegate?.log?(SQL)
        let sql:NSString = SQL
        var stmt:COpaquePointer = nil
        var result:CInt = sqlite3_prepare_v2(handle, sql.UTF8String, -1, &stmt, nil)
        if result != SQLITE_OK {
            sqlite3_finalize(stmt)
            return nil
        }
        return SQLite.ResultSet(stmt: stmt);
    }
    func execute(handle:COpaquePointer, SQL:String) -> NSError? {
        delegate?.log?(SQL)
        let sql:NSString = SQL
        var result:CInt = sqlite3_execute(handle,sql.UTF8String,nil,nil,nil)
        if result != SQLITE_OK {
            let error = String.fromCString(sqlite3_errmsg(handle))
            return NSError(domain: "QUERY SQL ERROR [\(SQL)] \(error)", code: Int(result), userInfo: ["path":path,"sql":SQL])
        }
        return nil
    }
}

//创建
extension SQLite : SQLiteCreate {
    
    func create(handle:COpaquePointer, tableName:String, params:[SQLite.ColumnHeader]) -> NSError? {
        var paramString = ""
        var first:Bool = true

        for column in params {
            if !first {
                paramString += ", "
            }
            first = false
            switch column {
            case let .SQL_Bool (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Int (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_UInt (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Float (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Double (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_String (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Date (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Data (name, state) :
                paramString += "\"\(name)\" \(column.name)\(state.name)"
            case let .SQL_Null (name, state) :
                paramString += "\"\(name)\" \(column.name)"
            }
        }
        
        let sql = "CREATE TABLE IF NOT EXISTS \"\(tableName)\" (\(paramString))"
        return execute(handle, SQL:sql)
    }
    

    func create(handle:COpaquePointer, tableName:String, params:[String:String], primaryKey:String, autoincrement:Bool) -> NSError? {
        var paramString = ""
        var first:Bool = true
        for (key,value) in params {
            if !first {
                paramString += ", "
            }
            first = false
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
    func update(handle:COpaquePointer, tableName:String, set params:[String:Any], Where:String?) -> NSError? {
        var paramString = ""
        var first:Bool = true
        for (key,value) in params {
            if !first {
                paramString += " AND "
            }
            first = false
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
    func insert(handle:COpaquePointer, tableName:String, params:[String:Any]) -> NSError? {
        var keyString = ""
        var valueString = ""
        var first:Bool = true
        for (key,value) in params {
            if !first {
                keyString += ", "
                valueString += ", "
            }
            first = false
            keyString += "\"\(key)\""
            valueString += "\"\(value)\""
        }
        let sql = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        return execute(handle, SQL:sql)
    }

    func insert(handle:COpaquePointer, tableName:String, columnNames:[String], columnValueFactory:(Int)->[SQLite.ColumnValue]?) -> NSError? {
        var keyString = ""
        var valueString = ""
        
        var first:Bool = true
        for columns in columnNames {
            if !first {
                keyString += ", "
                valueString += ", "
            }
            first = false
            keyString += "\"\(columns)\""
            valueString += "?"
        }
        //创建事务
        var queue:NSString = "BEGIN TRANSACTION"
        sqlite3_execute(handle, queue.UTF8String ,nil,nil,nil)
        
        //获取插入句柄绑定
        let SQL = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        delegate?.log?("SQL -> \(SQL)")
        let sql:NSString = SQL
        var stmt:COpaquePointer = nil
        var result:CInt = sqlite3_prepare_v2(handle, sql.UTF8String, -1, &stmt, nil)
        
        if result != SQLITE_OK {
            queue = "ROLLBACK TRANSACTION"
            sqlite3_finalize(stmt)
            sqlite3_execute(handle, queue.UTF8String ,nil,nil,nil)
            return NSError(domain: "插入数据错误", code: Int(result), userInfo:["sql":SQL])
        }

        let length = sqlite3_bind_parameter_count(stmt)
        let columns = NSArray(array: columnNames)
        
        var hasError = false
        var error:NSError? = nil
        
        var i = 0
        while let columnValues = columnValueFactory(i++) {
            var flag:CInt = 0
            for columnValue in columnValues {
                let (type,key,result) = columnValue.value
                let index = CInt(columns.indexOfObject(key)) + 1
                if index > length || index == 0 {
                    delegate?.log?("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(result)]失败,字段名无效")
                    flag = SQLITE_MISUSE //错误的使用函数
                    break;
                }
                switch type {
                case SQLITE_INTEGER:
                    let value:Int = result as Int
                    flag = sqlite3_bind_int(stmt,CInt(index),CInt(value))
                case SQLITE_FLOAT:
                    let value:Double = result as Double
                    flag = sqlite3_bind_double(stmt,CInt(index),CDouble(value))
                case SQLITE_TEXT:
                    let text:NSString = result as String
                    flag = sqlite3_bind_string(stmt,CInt(index),text.UTF8String,CInt(text.length),nil)
                case SQLITE_BLOB:
                    let data:NSData = result as NSData
                    flag = sqlite3_bind_data(stmt,CInt(index),data.bytes,CInt(data.length),nil)
                default://SQLITE_NULL:
                    flag = sqlite3_bind_null(stmt,CInt(index))
                }
                if flag != SQLITE_OK {
                    let error = String.fromCString(sqlite3_errmsg(handle))
                    delegate?.log?("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(result)]失败 ERROR \(error)")
                    break;
                }
            }
            if flag == SQLITE_OK {
                result = sqlite3_step(stmt)
                if result != SQLITE_OK && result != SQLITE_DONE {
                    hasError = true
                    let errormsg = String.fromCString(sqlite3_errmsg(handle))
                    error = NSError(domain: "严重错误并回滚插入的数据 STEP SQL[\(SQL)]ERROR \(errormsg)", code: Int(result), userInfo:["sql":SQL])
                    delegate?.log?("严重错误并回滚插入的数据 STEP SQL[\(SQL)]ERROR \(errormsg) result:\(result)")
                    break
                } else {    // <- 否则数据写入成功
                    sqlite3_clear_bindings(stmt)
                    sqlite3_reset(stmt)
                }
            } else {        // <- 否则数据绑定失败开始下一组
                sqlite3_clear_bindings(stmt)
            }
            
        }
        sqlite3_finalize(stmt)
        queue = hasError ? "ROLLBACK TRANSACTION" : "COMMIT TRANSACTION"
        sqlite3_execute(handle, queue.UTF8String ,nil,nil,nil)
        return error
    }
    
    //单条插入
    func insert(handle:COpaquePointer, tableName:String, params:[SQLite.ColumnValue]) -> NSError? {
        
        var columnNames:[String] = []
        for columns in params {
            columnNames += columns.name
        }
        return insert(handle, tableName: tableName,columnNames: columnNames){
            index in
            return index > 0 ? nil : params
        }
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
    //查询数量
    func count(handle:COpaquePointer, tableName:String, Where:String?) -> Int {
        var sql = "SELECT count(*) FROM \(tableName)"
        if let end = Where {
            sql += " WHERE \(end)"
        }
        var count:Int = 0
        if let rs = query(handle, SQL: sql) {
            if rs.next {
                count = Int(sqlite3_column_int(rs.stmt, 0))
            }
            rs.close()
        }
        return count
    }
    //普通查询
    func select(handle:COpaquePointer, params:[String]?, tableName:String, Where:String?) -> SQLite.ResultSet? {
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
    func select(handle:COpaquePointer, params:[String]?, tables:[String:String], Where:String?) -> SQLite.ResultSet? {
        var sql:String = "SELECT "
        if let array:NSArray = params {
            sql += array.componentsJoinedByString(", ")
        } else {
            sql += "*"
        }
        var paramString = ""
        var first:Bool = true
        for (key,value) in tables {
            if !first {
                paramString += ", "
            }
            first = false
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

extension SQLite {
    
    //查询结果集
    class ResultSet: NSObject {
        var stmt:COpaquePointer = nil
        let columnCount:Int = 0
        let columnNames:NSArray
        init (stmt:COpaquePointer) {
            self.stmt = stmt
            let length = sqlite3_column_count(stmt);
            var columns:[String] = []
            columnCount = Int(length)
            for i:CInt in 0..<length {
                //let tableName = String.fromCString(sqlite3_column_table_name(stmt, i))
                
                let name:ConstUnsafePointer<CChar> = sqlite3_column_name(stmt,i)
                columns += String.fromCString(name)!
            }
            columnNames = NSArray(array: columns)
        }
        deinit {
            if stmt {
                sqlite3_finalize(stmt)
            }
        }
        
        var next:Bool {
        return sqlite3_step(stmt) == SQLITE_ROW
        }
        var row:Int {
        return Int(sqlite3_data_count(stmt))
        }
    }
    
    //头附加状态
    enum ColumnState : Int {
        case SQL_Default = 0
        case SQL_PrimaryKey
        case SQL_PrimaryKeyAutoincrement
        case SQL_Autoincrement
        case SQL_NotNull
        var name:String {
        switch self {
        case .SQL_PrimaryKey :
            return " PRIMARY KEY"
        case .SQL_PrimaryKeyAutoincrement :
            return " PRIMARY KEY AUTOINCREMENT"
        case .SQL_Autoincrement :
            return " AUTOINCREMENT"
        case .SQL_NotNull :
            return " NOT NULL"
        default :
            return ""
            }
        }
    }
    
    //头本体
    enum ColumnHeader {
        case SQL_Bool (String ,SQLite.ColumnState)
        case SQL_Int (String ,SQLite.ColumnState)
        case SQL_UInt (String ,SQLite.ColumnState)
        case SQL_Float (String ,SQLite.ColumnState)
        case SQL_Double (String ,SQLite.ColumnState)
        case SQL_String (String ,SQLite.ColumnState)
        case SQL_Date (String ,SQLite.ColumnState)
        case SQL_Data (String ,SQLite.ColumnState)
        case SQL_Null (String ,SQLite.ColumnState)
        
        var name:String {
        switch self {
        case .SQL_Bool :
            return "BOOL"
        case .SQL_Int :
            fallthrough
        case .SQL_UInt :
            return "INTEGER"
        case .SQL_Float :
            return "FLOAT"
        case .SQL_Double :
            return "DOUBLE"
        case .SQL_String :
            return "TEXT"
        case .SQL_Date :
            return "DATETIME"
        case .SQL_Data :
            return "BLOB"
        case .SQL_Null :
            return "NULL"
            }
        }
    }
    
    enum ColumnValue {
        case SQL_Bool (String ,Bool)
        case SQL_Int (String ,Int)
        case SQL_UInt (String ,UInt)
        case SQL_Float (String ,Float)
        case SQL_Double (String ,Double)
        case SQL_String (String ,String)
        case SQL_Date (String ,NSDate)
        case SQL_Data (String ,NSData)
        case SQL_Null (String)
        
        //返回数据库类型和相应转化过的值
        var name:String {
        switch self {
        case .SQL_Bool  (let key, _):
            return key
        case .SQL_Int   (let key, _):
            return key
        case .SQL_UInt  (let key, _):
            return key
        case .SQL_Float (let key, _):
            return key
        case .SQL_Double(let key, _):
            return key
        case .SQL_String(let key, _):
            return key
        case .SQL_Date  (let key, _):
            return key
        case .SQL_Data  (let key, _):
            return key
        case .SQL_Null  (let key):
            return key
            }
            
        }
        
        var value:(CInt, String, Any!) {
        switch self {
        case let .SQL_Bool  (key, result):
            return (SQLITE_INTEGER, key, Int(result))
        case let .SQL_Int   (key, result):
            return (SQLITE_INTEGER, key, result)
        case let .SQL_UInt  (key, result):
            return (SQLITE_INTEGER, key, result)
        case let .SQL_Float (key, result):
            return (SQLITE_FLOAT  , key, Double(result))
        case let .SQL_Double(key, result):
            return (SQLITE_FLOAT  , key, result)
        case let .SQL_String(key, result):
            return (SQLITE_TEXT   , key, result)
        case let .SQL_Date  (key, result):
            //allow Natural Language
            let formater = NSDateFormatter()
            formater.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //formater.calendar = NSCalendar.currentCalendar()
            return (SQLITE_TEXT   , key, formater.stringFromDate(result))
        case let .SQL_Data  (key, result):
            return (SQLITE_BLOB   , key, result)
        case let .SQL_Null  (key):
            return (SQLITE_NULL   , key, nil)
            }
        }
    }
    // <- 自定义类型枚举结束
}


extension SQLite.ResultSet : SQLiteRowSet {
    
    func reset() {
        sqlite3_reset(stmt)
    }
    func close() {
        sqlite3_finalize(stmt)
        stmt = nil
    }
    func getDictionary() -> [String:Any] {
        var dict:[String:Any] = [:]
        for i in 0..<columnCount {
            let index = CInt(i)
            let type = sqlite3_column_type(stmt, index);
            let key:String = columnNames[i] as String
            var value:Any? = nil
            switch type {
            case SQLITE_INTEGER:
                value = Int(sqlite3_column_int(stmt, index))
            case SQLITE_FLOAT:
                value = Float(sqlite3_column_double(stmt, index))
            case SQLITE_TEXT:
                let text:ConstUnsafePointer<UInt8> = sqlite3_column_text(stmt, index)
                value = String.fromCString(ConstUnsafePointer<CChar>(text))
            case SQLITE_BLOB:
                let data:ConstUnsafePointer<()> = sqlite3_column_blob(stmt, index)
                let size:CInt = sqlite3_column_bytes(stmt, index)
                value = NSData(bytes:data, length: Int(size))
            case SQLITE_NULL:
                fallthrough     //下降关键字 执行下一 CASE
            default :
                break           //什么都不执行
            }
            //如果出现重名则
            if i != columnNames.indexOfObject(key) {
                //取变量类型
                //let tableName = String.fromCString(sqlite3_column_table_name(stmt, index))
                //dict["\(tableName).\(key)"] = value
                dict["\(key).\(i)"] = value
            } else {
                dict[key] = value
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
        let result = ConstUnsafePointer<CChar>(sqlite3_column_text(stmt, index))
        return String.fromCString(result)
    }
    func getData(columnName:String) -> NSData! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        let data:ConstUnsafePointer<()> = sqlite3_column_blob(stmt, index)
        let size:CInt = sqlite3_column_bytes(stmt, index)
        return NSData(bytes:data, length: Int(size))
    }
    func getDate(columnName:String) -> NSDate! {
        let index = CInt(columnNames.indexOfObject(columnName))
        if index < 0 {
            return nil
        }
        let columnType = sqlite3_column_type(stmt, index)
        
        switch columnType {
        case SQLITE_INTEGER:
            fallthrough
        case SQLITE_FLOAT:
            let time = sqlite3_column_double(stmt, index)
            return NSDate(timeIntervalSinceReferenceDate: time)
        case SQLITE_TEXT:
            let result = ConstUnsafePointer<CChar>(sqlite3_column_text(stmt, index))
            let date = String.fromCString(result)
            let formater = NSDateFormatter()
            formater.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //formater.calendar = NSCalendar.currentCalendar()
            return formater.dateFromString(date)
        default:
            return nil
        }
        
    }
}

