load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SGAPI",
    module_name = "SGAPI",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Shadowgram/SGLogging:SGLogging",
        "//Shadowgram/SGWebAppExtensions:SGWebAppExtensions",
        "//Shadowgram/SGSimpleSettings:SGSimpleSettings",
        "//Shadowgram/SGWebSettingsScheme:SGWebSettingsScheme",
        "//Shadowgram/SGRegDateScheme:SGRegDateScheme",
        "//Shadowgram/SGRequests:SGRequests",
        "//Shadowgram/SGConfig:SGConfig"
    ],
    visibility = [
        "//visibility:public",
    ],
)
