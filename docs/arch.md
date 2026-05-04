# PhotixMark iOS — Architecture

## Overview

PhotixMark is a 100% on-device iOS app that adds EXIF-metadata watermarks to photos. It is a faithful port of the [photix-mark-web](https://github.com/LeoonLiang/photix-mark-web) project.

All image processing happens locally. No network requests, no analytics, no data leaves the device.

---

## Layer Architecture

```
┌──────────────────────────────────────────┐
│          Presentation Layer               │
│  SwiftUI Views + @MainActor ViewModels   │
├──────────────────────────────────────────┤
│            Domain Layer                   │
│  Processors · Templates · Services       │
│  (pure Swift — no UIKit/SwiftUI imports) │
├──────────────────────────────────────────┤
│             Data Layer                    │
│  EXIFReader · PhotoImporter · Exporter   │
│  BrandLogoRepository                     │
└──────────────────────────────────────────┘
```

### Domain Layer
- Contains all business rules.
- **No UIKit, SwiftUI, or Foundation I/O** — only `CoreGraphics`, `CoreText`, `CoreImage`.
- Owns the processor pipeline, template registry, EXIF normalization, and template rendering.

### Data Layer
- Handles platform I/O: `ImageIO` for EXIF, `PhotosUI` for import, `PHPhotoLibrary` for export.
- `BrandLogoRepository`: persists custom brand logos to `FileManager` (Documents/BrandLogos/).

### Presentation Layer
- SwiftUI + `@MainActor ObservableObject` view models.
- `EditorViewModel` is the central state manager (mirrors web's `EditorPage.vue`).

---

## Processor Pipeline

Each processor implements `ImageProcessor` protocol:

```swift
protocol ImageProcessor: Sendable {
    var name: String { get }
    func process(_ ctx: ProcessorContext) async throws -> ProcessorContext
}
```

`ProcessorContext` carries:
- `layers: [CGImage]` — multi-layer buffer (equivalent to web's `HTMLCanvasElement[]`)
- `exif: ExifData` — merged EXIF (raw + user overrides)
- `userOptions: TemplateUserOptions` — user-visible config
- `stepConfig: [String: StepValue]` — per-step config from template definition
- `customLogos: [String: Data]` — brand → PNG Data

### Registered Processors

| Name | Description |
|---|---|
| `blur` | Gaussian blur via `CIFilter.gaussianBlur` |
| `shadow` | Drop shadow via `cgContext.setShadow` |
| `rounded_corner` | CGPath clip to rounded rect |
| `margin` | Padding with background fill |
| `rich_text` | Single text string → new CGImage layer |
| `multi_rich_text` | Multiple text segments side-by-side |
| `watermark` | Main watermark bar (text + logo) below photo |
| `concat` | Merge layers vertically or horizontally |
| `resize` | Scale layer by factor or to target size |
| `crop` | Crop layer to sub-rectangle |
| `alignment` | Overlay one layer on another with alignment |
| `flex_layout` | Flexible section-based watermark bar |

---

## Template System

Templates are `TemplateConfig` value types registered at app launch via `ProcessorRegistry.shared.registerAll()`.

Each template defines:
- `processors: TemplateProcessors` — `.fixed([ProcessorStep])` or `.responsive(landscape:portrait:square:)`
- `defaultOptions: TemplateUserOptions` — initial user-configurable values

### Available Templates

| ID | Name | Key Feature |
|---|---|---|
| `noProcess` | No Watermark | Pass-through |
| `standard1` | Classic Layout | 4-corner + logo |
| `standard2` | Classic Layout 2 | Brand+model left, params right |
| `logoCentered` | Logo Centered | Logo in center of bar |
| `blurBackground` | Blur Background | Photo on blurred self |
| `nikonBlur` | Nikon Style | Yellow bar + blur bg |
| `folderNameParams` | Params Focus | Large params text |
| `centeredWatermark` | Centered Style | All centered |
| `centeredWatermark2` | Centered Style 2 | Logo + text centered |
| `sidebarWatermark` | Sidebar Style | Dark bar |

---

## State Management

```
EditorViewModel (@MainActor ObservableObject)
  ├── photoItems: [PhotoItem]
  ├── exifCache: [UUID: ExifData]         ← raw EXIF from ImageIO
  ├── imageStates: [UUID: ImageState]     ← templateId + overrides per photo
  ├── processedCache: [UUID: CGImage]     ← invalidated on config/template change
  ├── customLogos: [String: Data]         ← brand → logo data
  └── processingProgress: BatchProgress?
```

Data flow: `User action → ViewModel method → BatchProcessingService (AsyncThrowingStream) → processedCache → SwiftUI re-render`

---

## Key Design Decisions

1. **Y-axis flip**: CGContext origin is bottom-left; all draws use `CGContextHelpers.draw(_:in:at:)` which applies `translateBy(x:0,y:height); scaleBy(x:1,y:-1)`.
2. **Fraction-based sizing**: Values < 2 are treated as fractions of a reference dimension (mirrors web convention).
3. **Sequential batch processing**: Processes one image at a time to avoid memory pressure on large HEIC files.
4. **No ZIP export**: Unlike the web app, iOS saves directly to the photo library (simpler, more native).
5. **Template config is typed**: `TemplateUserOptions` is a typed struct (vs. web's `Record<string,any>`), enabling compile-time safety and SwiftUI `Binding`.

---

## Directory Structure

```
PhotixMark/
  Sources/
    App/           Entry point, navigation
    Domain/
      Models/      ExifData, ImageState, ProcessorContext, TemplateConfig, ProcessorStep
      Protocols/   ImageProcessor
      Processors/  12 processor implementations + CGContextHelpers
      Templates/   10 template definitions + TemplateRegistry
      Services/    ImageProcessingService, BatchProcessingService,
                   ExifNormalizer, TemplateRenderer, LogoResolver, ProcessorRegistry
    Data/
      EXIF/        EXIFReader (ImageIO)
      Import/      PhotoLibraryImporter (PhotosUI)
      Persistence/ BrandLogoRepository
      Export/      ImageExporter (PHPhotoLibrary)
    Presentation/
      Screens/     Home, Editor, TemplateConfig, ExifEditor, BrandLogo, Progress, ImageSelector
      Components/  ImageCarouselView, ImagePreviewView, TemplateSelectorView, ToastView
      Styles/      AppTheme
  Resources/
    Assets.xcassets/Logos/   18 bundled brand logos
  Tests/
    Unit/          ExifNormalizerTests, TemplateRendererTests, ProcessorTests/
    Integration/   ImageProcessingServiceTests
    Snapshot/      TemplateSnapshotTests
```
