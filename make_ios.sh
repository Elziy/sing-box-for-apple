XCODEPROJ_NAME=sing-box
APPLICATION_NAME=sing-box
SCHEME_NAME=SFI

xcodebuild -project $XCODEPROJ_NAME.xcodeproj -scheme $SCHEME_NAME -destination generic/platform=iOS -configuration Debug -sdk iphoneos build install STRIP_INSTALLED_PRODUCT=NO ARCHS=arm64 CODE_SIGNING_ALLOWED=NO ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO ENABLE_BITCODE=NO DSTROOT=packages/

ldid -SSFI/SFI.entitlements packages/Applications/$APPLICATION_NAME.app/$APPLICATION_NAME
ldid -SExtension/Extension.entitlements packages/Applications/$APPLICATION_NAME.app/PlugIns/Extension.appex/Extension
ldid -SIntentsExtension/IntentsExtension.entitlements packages/Applications/$APPLICATION_NAME.app/Extensions/IntentsExtension.appex/IntentsExtension

mkdir -p packages/Payload
cp -rp packages/Applications/$APPLICATION_NAME.app packages/Payload
cd packages
zip -qr $APPLICATION_NAME.tipa Payload
rm -r Payload