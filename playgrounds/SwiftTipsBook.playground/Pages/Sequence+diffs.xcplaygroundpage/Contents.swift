//: [Previous](@previous)

import Foundation

/*:
 
 ## 差分更新を行うには
 
 ### データの単一性
 
 差分要素のみに更新処理を実施する場合、全要素に対してそれぞれが識別できる固定値が必要です。
 この固定値がなぜ必要かというと、１つのデータソース内の要素はそれぞれユニークに存在することを要請する場合、
 たとえ同じデータコンテンツであっても、各要素が同じではないことを判定する必要だからです。
 かつ重複を許さないような性質が要求されるためです。
 
 ### データ比較
 
 各データを区別するために識別子を用意するため、次の方法を用意しました。
 
 1.  プロトコル
 2.  キーパス指定

 
 */

//: 1. プロトコル方式
protocol IdentifiableType {
    associatedtype Identity: Hashable
    /// ユニークな値を設定する
    var identity: Identity { get }
}
/*: 例1
 Animalというオブジェクトがあった場合、次のとおりになります。
 以下では `id` に対する重複を許していません、
*/
struct Animal: Equatable {
    var id: String
    var name: String
}

extension Animal: IdentifiableType {
    typealias Identity = String
    
    var identity: String {
        return id
    }
}


extension Sequence where Self.Element: IdentifiableType & Equatable {
    
    func updateDiff(_ diffs: [Element]) -> [Element] {
        let source = self
        var dist: [Element] = []
        for ( i, old) in source.enumerated() {
            var temp = old
            /// 同じIDに対して、差分があれば更新する
            for ( j, new) in diffs.enumerated() where new.identity == old.identity && new != old {
                temp = new
                print("diff: \(i) \(old) >>>> \(j) \(new)")
            }
            dist.append(temp)
        }
        return dist
    }
    
}


//: データソース
let src = [Animal(id: "0", name: "いぬ"),
           Animal(id: "1", name: "ねこ"),
           Animal(id: "2", name: "コアラ"),
           Animal(id: "3", name: "クジラ"),
           Animal(id: "4", name: "うさぎ"),
           Animal(id: "5", name: "ぱんだ")]
//: 変更データ
let diffs = [Animal(id: "0", name: "かぴばら")]

//: プロトコルで指定するケース
let result1 = src.updateDiff(diffs)


//: 2. キーパス方式
extension Sequence where Self.Element: Equatable {
    
    /**
     データソースに対して差分要素のみをデータ更新し、マージ後の配列を返します。（再帰関数）
     
     - parameter diffs: 差分要素を配列で渡します
     - parameter keyPath: 識別対処をKeyPathで指定します
     - returns: 差分適用後の配列を返す
     
     */
    func apply<T: Equatable>(diffs: [Element], atPrimaryKey keyPath: KeyPath<Element, T>) -> [Element] {
        // 差分データが空ならば終了する
        if diffs.isEmpty {
            return self.map({ $0 })
        } else {
            // 差分データを１つ取り出す
            let new = diffs.first!
            // 適用後の配列データ
            var latestSrc: [Element] = []
            for (i, old) in self.enumerated() {
                // i番目に差分が発生していれば, 新しいデータを適用する
                if old[keyPath: keyPath] == new[keyPath: keyPath] && old != new {
                    print("diff: \(i) \(old) >>>> \(new)")
                    latestSrc.append(new)
                } else {
                    latestSrc.append(old)
                }
            }
            // 未適用の差分データのみを残す
            let otherDiffs = Array(diffs.dropFirst())
            // 適用後の配列を使って、残りの差分も適用する
            return latestSrc.apply(diffs: otherDiffs, atPrimaryKey: keyPath)
        }
    }


    /**
        データソースに対して差分要素のみをデータ更新し、マージ後の配列を返します。（単純ループ計算）
     
        - parameter diffs: 差分要素を配列で渡します
        - parameter keyPath: 識別対処をKeyPathで指定します
        - returns: 差分適用後の配列を返す
     
     */
    func apply<T: Equatable>(_ diffs: [Element], at keyPath: KeyPath<Element, T>) -> [Element] {
        
        let source = self
        var dist: [Element] = []
        var _diffs = diffs
        for ( i, old) in source.enumerated() {
            var removeIndex = -1
            var temp = old
            let oldIdentity = old[keyPath: keyPath]
            /// 同じIDに対して、差分があれば更新する
            for ( j, new) in _diffs.enumerated() {
                let newIdentity = new[keyPath: keyPath]
                if oldIdentity == newIdentity && old != new {
                    temp = new
                    removeIndex = j
                    print("diff: \(i) \(old) >>>> \(j): \(new)")
                }
            }
            
            // 適用後のdiffは削除
            if removeIndex != -1 {
                _diffs.remove(at: removeIndex)
            }
            dist.append(temp)
        }
        return dist
    }
}


struct Food: Equatable {
    var id: String
    var name: String
}

//: データソース
let src2 = [Food(id: "0", name: "いぬ"),
           Food(id: "1", name: "ねこ"),
           Food(id: "2", name: "コアラ"),
           Food(id: "3", name: "クジラ"),
           Food(id: "4", name: "うさぎ"),
           Food(id: "5", name: "ぱんだ")]
//: 変更データ
let diffs2 = [Food(id: "0", name: "かぴばら")]

//: キーパス指定するケース
let result2 = src2.apply(diffs: diffs2, atPrimaryKey: \Food.id)


//: [Next](@next)
