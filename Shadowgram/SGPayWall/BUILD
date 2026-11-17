load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

filegroup(
    name = "SGPayWallAssets",
    srcs = glob(["Images.xcassets/**"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "SGPayWall",
    module_name = "SGPayWall",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Shadowgram/SGIAP:SGIAP",
        "//Shadowgram/SGLogging:SGLogging",
        "//Shadowgram/SGSimpleSettings:SGSimpleSettings",
        "//Shadowgram/SGSwiftUI:SGSwiftUI",
        "//Shadowgram/SGStrings:SGStrings",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
