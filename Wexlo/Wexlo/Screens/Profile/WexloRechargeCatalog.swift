import Foundation

struct WexloRechargePackage: Equatable {
    let productID: String
    let coinAmount: Int
    let amount: String
    let price: String
}

enum WexloRechargeCatalog {
    static let packages = [
        WexloRechargePackage(productID: "wexlo.coins.400", coinAmount: 400, amount: "400", price: "$0.99"),
        WexloRechargePackage(productID: "wexlo.coins.800", coinAmount: 800, amount: "800", price: "$1.99"),
        WexloRechargePackage(productID: "wexlo.coins.2450", coinAmount: 2450, amount: "2,450", price: "$4.99"),
        WexloRechargePackage(productID: "wexlo.coins.5150", coinAmount: 5150, amount: "5,150", price: "$9.99"),
        WexloRechargePackage(productID: "wexlo.coins.6400", coinAmount: 6400, amount: "6,400", price: "$12.99"),
        WexloRechargePackage(productID: "wexlo.coins.10800", coinAmount: 10800, amount: "10,800", price: "$19.99"),
        WexloRechargePackage(productID: "wexlo.coins.14900", coinAmount: 14900, amount: "14,900", price: "$24.99"),
        WexloRechargePackage(productID: "wexlo.coins.29400", coinAmount: 29400, amount: "29,400", price: "$49.99"),
        WexloRechargePackage(productID: "wexlo.coins.39500", coinAmount: 39500, amount: "39,500", price: "$79.99"),
        WexloRechargePackage(productID: "wexlo.coins.63700", coinAmount: 63700, amount: "63,700", price: "$99.99")
    ]
}
