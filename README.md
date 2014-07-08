SQLite-Base-Swift
=================

  引用 libsqlite.3.0.dylib
  需要建立 ProjectName-Bridging-Header.h 桥文件,并写下 #import "sqlite3.h"

  使用例子如下 : (OS X 开发也可以用)

//////////////////////////////////////////////////////////////////////////////////////////////

    extension ViewController : SQLiteDelegate {
        func create(handle:COpaquePointer, sqlite:SQLite) {
            //创建电脑表
            sqlite.create(handle,
                tableName: "Computer",
                params:    [.SQL_Int    ("cid",  .SQL_PrimaryKeyAutoincrement),
                            .SQL_String ("brand",.SQL_NotNull),
                            .SQL_Int    ("cpu", .SQL_NotNull)])
            //创建处理器表
            sqlite.create(handle,
                tableName: "CPU",
                params:    [.SQL_Int    ("uid",  .SQL_PrimaryKeyAutoincrement),
                            .SQL_String ("firm",.SQL_NotNull)])
            //创建使用者表
            sqlite.create(handle,
                tableName: "Preson",
                params:    [.SQL_Int    ("pid",  .SQL_PrimaryKeyAutoincrement),
                            .SQL_String ("name",.SQL_NotNull),
                            .SQL_Int    ("computer",.SQL_Default)])
            
            sqlite.insert(handle, tableName: "CPU", params:["firm":"AMD"])
            sqlite.insert(handle, tableName: "CPU", params:["firm":"Intel"])
            
            sqlite.insert(handle, tableName: "Computer", params:["brand":"Apple", "cpu":2])
            sqlite.insert(handle, tableName: "Computer", params:["brand":"Hp", "cpu":1])
            sqlite.insert(handle, tableName: "Computer", params:["brand":"Dell", "cpu":2])
            
            //批量插入
            let names = ["lzl","lc","jc","gd"]
            sqlite.insert(handle, tableName: "Preson", columnNames:["name","computer"]){
                index in
                if index < names.count {
                    return [.SQL_String ("name"     ,names[index]),
                            .SQL_Int    ("computer" ,1)]
                } else {
                    return nil
                }
            }

            println("插入完成")
            
        }
    }

///////////////////////////////////////////////////////////////////////////////////////////////////////

  在需要查询的时候代码如下
    extension ViewController : SQLiteDelegate {


  let sqlite = SQLite(path:"/Users/apple/Documents/test.sqlite",delegate:self)

  let (handle,_) = sqlite.open()
  let count = sqlite.count(handle,tableName: "Preson", Where: "computer = 1")
  println("有苹果电脑的人数为\(count)")

  //查询所有电脑品牌为 Apple的数据
  if let rs = sqlite.select(handle,params:nil, tables: ["p":"Preson","cp":"Computer","c":"CPU"], Where: "p.computer = cp.cid AND cp.cpu = c.uid AND p.computer = 1") {
      println("查询成功")
      while rs.next {
          let dict = rs.getDictionary()
          println("data:\(dict)")
      }
    
  } else {
      println("查询失败")
  }
}
