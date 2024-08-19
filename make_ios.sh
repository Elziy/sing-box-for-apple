XCODEPROJ_NAME=sing-box
APPLICATION_NAME=sing-box
SCHEME_NAME=SFI

xcodebuild -project $XCODEPROJ_NAME.xcodeproj -scheme $SCHEME_NAME -destination generic/platform=iOS -configuration Debug -sdk iphoneos build install STRIP_INSTALLED_PRODUCT=NO ARCHS=arm64 CODE_SIGNING_ALLOWED=NO ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO ENABLE_BITCODE=NO DSTROOT=package/

ldid -SSFI/SFI.entitlements package/Applications/$APPLICATION_NAME.app/$APPLICATION_NAME
ldid -SExtension/Extension.entitlements package/Applications/$APPLICATION_NAME.app/PlugIns/Extension.appex/Extension
ldid -SIntentsExtension/IntentsExtension.entitlements package/Applications/$APPLICATION_NAME.app/Extensions/IntentsExtension.appex/IntentsExtension

mkdir -p package/Payload
cp -rp package/Applications/$APPLICATION_NAME.app package/Payload
cd package
zip -qr $APPLICATION_NAME.tipa Payload
rm -r Payload