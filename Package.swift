// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dickerator",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Dickerator",
            targets: ["Dickerator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "Dickerator",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "Dickerator"
        )
    ]
)
