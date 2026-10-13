# ShopeeBlocker

**Stop Facebook from unexpectedly opening Shopee.**

Ever tapped a link while scrolling Facebook and suddenly found yourself inside the Shopee app, on a shop or product page? Or got an **“Open in Shopee”** popup where choosing **OK** or **Cancel** still ended up opening Shopee?

**ShopeeBlocker** is a small, always-on iOS tweak that blocks the Shopee deep-link and short-link paths currently observed in Facebook. No toggle, no Settings page, no logging: **install it to block; uninstall it to stop blocking.**

## What it blocks

- Shopee app deep links using `shopeevn://`.
- Shopee short links on the exact host `s.shopee.vn`.
- The immediately correlated Facebook in-app-browser popup, when triggered by a blocked Shopee URL (best-effort, one-second correlation window).

Unrelated links are passed through unchanged. The tweak intentionally does **not** block every `shopee.vn` subdomain or arbitrary URLs containing “shopee.” Shopee/Facebook may change their link handling; please report reproducible misses in GitHub Issues.

## Installation

### Jailbroken iPhone (rootless)

Build a `.deb` using Theos and install it with a package manager compatible with rootless jailbreaks. The tweak is restricted to the Facebook bundle ID `com.facebook.Facebook`.

### Sideloaded Facebook IPA

Build the tweak, extract **`ShopeeBlocker.dylib`** from the `.deb` (or use the compiled dylib), inject it into the Facebook IPA with a compatible injection tool, and sign the resulting IPA. **Keep the exact filename `ShopeeBlocker.dylib`**; renaming it can prevent some injectors from loading the tweak. An appropriate hook runtime is required; simply copying the dylib into an IPA is not sufficient.

## Build

Requires Theos and compatible iOS SDK / substrate hook runtime.

```sh
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

The compiled tweak is named `ShopeeBlocker.dylib`; package identifier: `com.ttlongdl.shopeeblocker`.

## How it works

ShopeeBlocker hooks `UIApplication` URL-opening methods and narrowly intercepts Shopee URLs. It additionally suppresses a Facebook in-app-browser presentation only when correlated with a blocked Shopee URL. The correlation logic is deliberately narrow to avoid interfering with unrelated Facebook navigation.

## Compatibility and caveats

- Current source targets **rootless** packaging on iOS 17+ with Theos; other jailbreak environments require an appropriate build and test.
- Hooking Facebook internals is inherently version-dependent. An app update may change the relevant URL pathways or UI behavior.
- Tested by the maintainer on a jailbroken iPhone and on a separately signed/injected Facebook IPA; individual injector/signing setups vary.
- No in-app settings, analytics, diagnostic probes, or persistent logging.

## License

No license file is currently included. Redistribution/reuse rights are not granted by default; add an explicit license if you want to permit third-party reuse.
