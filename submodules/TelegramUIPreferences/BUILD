load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

sgsrcs = [
    "//Shadowgram/SGStatus:SGStatus"
]

swift_library(
    name = "TelegramUIPreferences",
    module_name = "TelegramUIPreferences",
    srcs = sgsrcs + glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Shadowgram/UgramSettings:UgramSettings",
    ],
    visibility = [
        "//visibility:public",
    ],
)
