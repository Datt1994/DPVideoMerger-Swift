// swift-tools-version:5.0
//
//  Package.swift
//

import PackageDescription

let package = Package(name: "DPVideoMerger-Swift",
                      platforms: [.iOS(.v10)],
                      products: [.library(name: "DPVideoMerger-Swift",
                                          targets: ["DPVideoMerger-Swift"])],
                      targets: [.target(name: "DPVideoMerger-Swift",
                                        path: "DPVideoMerger/DPVideoMerger/",
                                        publicHeadersPath: "")],
                      swiftLanguageVersions: [.v5])
