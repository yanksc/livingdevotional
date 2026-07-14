# Living Devotional — Claude Notes

## Bundle Identifiers (DO NOT CHANGE)

The widget extension bundle identifier is registered in Apple Developer portal as **all-lowercase**. Never change capitalization.

| Target | Bundle ID |
|---|---|
| Main app | `com.ykh.livingdevotional` |
| Widget extension | `com.ykh.livingdevotional.livingpathwidget` |

The target/product name can be `LivingPathWidgetExtension` (PascalCase is fine for Xcode targets), but `PRODUCT_BUNDLE_IDENTIFIER` in `project.pbxproj` must stay lowercase for the widget.

## No Xcode Builds

Do not run `xcodebuild` on behalf of the user — builds take too long.
