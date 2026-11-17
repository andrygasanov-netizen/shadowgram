load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

sgdeps = [
    "//Shadowgram/SGSimpleSettings:SGSimpleSettings",
]

sgsrc = [
    "//Shadowgram/SGChatListSimpleSettingsSignal:SGSimpleSettingsBoolSignal", # MARK: Shadowgram
    "//Shadowgram/SGTabBarHeightModifier:SGTabBarHeightModifier"
]

swift_library(
    name = "TabBarUI",
    module_name = "TabBarUI",
    srcs = sgsrc + glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = sgdeps + [
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
    	"//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode",
        "//submodules/TelegramPresentationData",
        "//submodules/ComponentFlow",
        "//submodules/Components/ComponentDisplayAdapters",
        "//submodules/TelegramUI/Components/TabBarComponent",
        "//submodules/TelegramUI/Components/TabBarLayout",
        "//submodules/TelegramUI/Components/GlassControls",
    ],
    visibility = [
        "//visibility:public",
    ],
)
