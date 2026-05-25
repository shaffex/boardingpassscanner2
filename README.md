
CloudKit container:
com.shaffex.boardingpassscanner

Bundle ID:
com.shaffex.boardingpassscanner

## Scanning Flow

All boarding pass scan entry points use the same event pipeline:

- Scan boarding pass from Camera
- Import boarding pass from Photos
- Paste boarding pass from Clipboard

Each scanner is responsible only for detecting barcode content and setting:

- `barcodeObject.text`
- `barcodeObject.type`

After that, every scanner fires the shared `onBarcodeDetected` event.

`MainScreen.xml` handles `onBarcodeDetected` with:

```xml
<event onBarcodeDetected="" action="playSystemSound:1017\\addNewBoardingPass:type:$barcodeObject.type;text:$barcodeObject.text"/>
```

This keeps camera, photos, and clipboard imports consistent. Any future scanning source should also set `barcodeObject.text`, set `barcodeObject.type`, and fire `onBarcodeDetected`.

## Add Boarding Pass Logic

Validation and duplicate checks are centralized in the `addNewBoardingPass` action.

`addNewBoardingPass` is responsible for:

- Checking whether the boarding pass was already added.
- Showing `myAlertBoardingPassAlreadyExists` when a duplicate is found.
- Checking whether the detected barcode text is a valid boarding pass.
- Showing `myAlertInvalidBoardingPassCode` when the barcode is not a valid boarding pass.
- Adding valid, new boarding passes to `dataModelMyCodes`.

Scanning functions should not duplicate this logic. They should only detect barcode content and emit `onBarcodeDetected`.

## Events

- `onBarcodeDetected`: fired by camera, photos, and clipboard scanning after barcode content is detected.
- `onBoardingPassAdded`: future event for successful add handling.
- `onBoardingPassAlreadyExists`: future event for duplicate handling.
- `onBoardingPassInvalid`: future event for invalid boarding pass handling.

## Code Types From Scanner

- `org.iso.PDF417`
- `org.iso.Aztec`
- `org.iso.QRCode`
- `org.iso.DataMatrix` - verify support before relying on it.

## Tested

- Disabled rotation for iPhone.
