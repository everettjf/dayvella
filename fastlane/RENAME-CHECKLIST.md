# Dayvella App Store rename

Use the existing App Store Connect app record **6753280745**. Do not create a new app or change `com.xnu.countmydays`. The owner will update App Store Connect manually.

## Prepared metadata

Both `metadata/en-US` and `metadata/zh-Hans` contain the name Dayvella, release notes explaining the rename, and the new support, marketing and privacy URLs. Existing localized subtitles, keywords and promotional text remain available. Apply Dayvella to any additional storefront localizations already configured in App Store Connect.

- Name: Dayvella
- Support / marketing: https://xnu.app/dayvella/
- Privacy: https://xnu.app/dayvella/privacy/
- Existing App Store record: https://appstoreconnect.apple.com/apps/6753280745/distribution/info

## Release checklist

1. Save the new app name in the editable App Information localization(s).
2. Use the existing app record and provisioning identities.
3. Update the description to say Dayvella, retaining one “formerly CountMyDays” reference for returning users.
4. Apply the prepared release notes and replace screenshots containing the old name.
5. Build/archive the Dayvella scheme, choose an unused build number, upload and submit through the normal release workflow. The repository rename does not itself publish a new App Store binary.
6. After Apple publishes the update, verify the store name and website link for the same numeric app ID.

The project remains at version 1.2 / build 116 from the existing development checkout. A new store build was not uploaded or submitted as part of this rename.
