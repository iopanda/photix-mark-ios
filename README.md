# PhotixMark

Add beautiful EXIF watermarks to your photos — 100% on device.

PhotixMark automatically reads camera metadata (brand, model, lens, aperture, shutter speed, ISO, focal length, date) from your photos and renders it as a watermark in one of 10 curated templates. Everything runs locally; no photo ever leaves your device.

---

## Screenshots

> _Add screenshots here_

---

## Features

- **Auto EXIF extraction** — reads make, model, lens, focal length, aperture, shutter speed, ISO, and date/time directly from the image file
- **10 watermark templates** — Original, Classic, Minimal, Framed, Magazine, Brand Mark, Logo Top, Logo Bottom, Artistic, Z Series
- **Batch processing** — apply a template to all photos or a custom selection at once
- **Custom brand logos** — upload your own logo per camera brand; falls back to a bundled default
- **EXIF editor** — manually override any metadata field before rendering
- **Per-photo template settings** — each photo can carry its own template, colors, layout, and visibility options
- **Export** — save processed photos back to the iOS Photo Library or as JPEG files on macOS
- **100% on-device** — no network requests, no cloud uploads, no tracking
- **Multilingual** — English, Simplified Chinese, Traditional Chinese, Japanese, Korean (follows system language automatically)

---

## Requirements

| Platform | Minimum OS |
|----------|-----------|
| iOS / iPadOS | 16.0+ |
| macOS | 14.0+ |

- Xcode 15+
- Swift 5.9+

---

## Getting Started

```bash
git clone https://github.com/iopanda/PhotixMark.git
cd PhotixMark
open PhotixMark.xcodeproj
```

Select your target device in Xcode and press **Run** (⌘R).

No external dependencies — the project uses only Apple frameworks (SwiftUI, CoreGraphics, ImageIO, Photos, PhotosUI).

---

## Project Structure

```
PhotixMark/
├── Sources/
│   ├── App/                        # App entry point & coordinator
│   ├── Domain/
│   │   ├── Models/                 # ExifData, PhotoItem, TemplateConfig, ImageState …
│   │   ├── Processors/             # Composable image processors (blur, watermark, layout …)
│   │   ├── Templates/              # 10 template definitions
│   │   └── Services/               # ImageProcessingService, BatchProcessingService, ExifNormalizer …
│   ├── Data/
│   │   ├── EXIF/                   # EXIFReader
│   │   ├── Import/                 # PhotoLibraryImporter (iOS), MacPhotoImporter
│   │   ├── Export/                 # ImageExporter (iOS), MacImageExporter
│   │   └── Persistence/            # BrandLogoRepository
│   └── Presentation/
│       ├── Screens/                # HomeView, EditorView, TemplateConfigView, ExifEditorView …
│       ├── Components/             # ImageCarouselView, TemplateSelectorView, ToastView …
│       └── Styles/                 # AppTheme
└── Resources/
    ├── Localizable.xcstrings       # Translations (en, zh-Hans, zh-Hant, ja, ko)
    └── Assets.xcassets
```

### Architecture

The project follows **Domain-Driven Design** with a clean layered architecture:

- **Domain** — pure Swift, no UI or framework dependencies; contains all business logic
- **Data** — platform-specific I/O (photo import, EXIF reading, file export, logo persistence)
- **Presentation** — SwiftUI views and `ObservableObject` view models; reads from Domain, writes through view models

Image processing is built as a **composable processor pipeline**: each `ImageProcessor` takes a `ProcessorContext` and returns a new `CGImage`. Templates declare an ordered list of `ProcessorStep` values; `ImageProcessingService` executes them in sequence.

---

## Templates

| Name | ID | Description |
|------|----|-------------|
| Original | `noProcess` | No watermark applied |
| Classic | `standard1` | Bottom bar with brand, model, and EXIF grid |
| Minimal | `standard2` | Clean single-line EXIF caption |
| Framed | `blurBackground` | Blurred background with centered photo |
| Magazine | `centeredWatermark` | Centered overlay watermark |
| Brand Mark | `centeredWatermark2` | Bold centered brand watermark |
| Logo Top | `logoCentered` | Logo centered at top |
| Logo Bottom | `sidebarWatermark` | Sidebar layout with logo |
| Artistic | `nikonBlur` | Nikon-style blur composite |
| Z Series | `folderNameParams` | Folder-name-driven parameter template |

---

## Localization

All UI strings are managed in a single **String Catalog** (`Resources/Localizable.xcstrings`). To add a new language, open the file in Xcode and add a translation column — no code changes required.

Supported languages: English · 简体中文 · 繁體中文 · 日本語 · 한국어

---

## Acknowledgements

This project was inspired by **[photix-mark-web](https://github.com/LeoonLiang/photix-mark-web)** by [@LeoonLiang](https://github.com/LeoonLiang) — a beautifully crafted browser-based EXIF watermark tool built with Nuxt 3 and Vue 3.

If you are looking for a web version that works directly in your browser without any installation, go check it out at **[mark.photix.cc](https://mark.photix.cc)**. All the core ideas around template design, EXIF field display, and batch processing in PhotixMark originate from that project.

A big thank you to LeoonLiang for the original concept and open-source spirit. ⭐ Star the web project if you find it useful!

---

## License

MIT License. See [LICENSE](LICENSE) for details.
