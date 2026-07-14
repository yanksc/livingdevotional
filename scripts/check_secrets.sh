#!/bin/bash
# check_secrets.sh
#
# Fails the build if a secret in LocalSecrets.xcconfig is missing or still set
# to its LocalSecrets.xcconfig.template placeholder value. Xcode exposes build
# settings (including xcconfig values) as environment variables to Run Script
# build phases, so this reads them the same way the compiled app would.
#
# Add as a Run Script build phase on the main app target (Build Phases > + >
# New Run Script Phase), placed before "Compile Sources". This catches a
# forgotten/placeholder key at build time on your machine, instead of it
# silently shipping in an Archive and failing invisibly for every user
# (including App Review).

set -euo pipefail

fail=0

check_secret() {
    local name="$1"
    local value="$2"
    local placeholder="$3"
    if [ -z "$value" ] || [ "$value" = "$placeholder" ]; then
        echo "error: $name is missing or still set to its placeholder value in LocalSecrets.xcconfig. Fill in a real key before building for $CONFIGURATION."
        fail=1
    fi
}

check_secret "HELICONE_API_KEY" "${HELICONE_API_KEY:-}" "your-api-key-here"
check_secret "REVENUECAT_APPLE_API_KEY" "${REVENUECAT_APPLE_API_KEY:-}" "your-revenuecat-production-key-here"

if [ "$CONFIGURATION" = "Release" ]; then
    case "${REVENUECAT_APPLE_API_KEY:-}" in
        test_*)
            echo "error: REVENUECAT_APPLE_API_KEY is a Test Store key (test_*) — Release/Archive builds must use the Production (Apple) key from the RevenueCat dashboard."
            fail=1
            ;;
    esac
fi

exit $fail
