load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SGRegDate",
    module_name = "SGRegDate",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Shadowgram/SGRegDateScheme:SGRegDateScheme",
        "//Shadowgram/SGSimpleSettings:SGSimpleSettings",
        "//Shadowgram/SGAPI:SGAPI",
        "//Shadowgram/SGAPIToken:SGAPIToken",
        "//Shadowgram/SGDeviceToken:SGDeviceToken",
        "//Shadowgram/SGStrings:SGStrings",

        "//submodules/AccountContext:AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)