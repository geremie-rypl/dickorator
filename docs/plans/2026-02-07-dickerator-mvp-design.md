# Dickerator MVP Design

**Date**: 2026-02-07
**Status**: Approved

---

## Overview

Dickerator is a campy, Gen Z-focused photo app that transforms banana-shaped objects into shareable, absurd art using curated filters and stickers.

**Target**: Gen Z and LGBTQ+ audiences who enjoy ironic humor and novelty apps.

**Core Loop**: Capture banana → Apply filter/stickers → Share → Recipient downloads app → Repeat.

---

## Tech Stack

- **Platform**: iOS 17+ (SwiftUI)
- **Architecture**: MVVM with Services
- **Dependencies**: Swift Package Manager
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Payments**: StoreKit 2

---

## Project Structure

```
Dickerator/
├── App/
│   ├── DickeratorApp.swift          # Entry point, Firebase init
│   └── AppState.swift               # Global app state (auth, entitlements)
├── Features/
│   ├── Camera/
│   │   ├── CameraView.swift         # AVFoundation camera preview
│   │   ├── CameraViewModel.swift    # Capture logic, permissions
│   │   └── CameraService.swift      # AVCaptureSession wrapper
│   ├── Editor/
│   │   ├── EditorView.swift         # 3-layer compositing canvas
│   │   ├── EditorViewModel.swift    # Undo/redo, layer state
│   │   ├── FilterOverlayView.swift  # Static PNG overlay
│   │   └── StickerView.swift        # Transformable sticker
│   ├── Showcase/
│   │   ├── ShowcaseView.swift       # Feed of user creations
│   │   ├── ShowcaseViewModel.swift  # Firestore queries
│   │   └── BananaCard.swift         # Single post cell
│   └── Store/
│       ├── StoreView.swift          # IAP browsing UI
│       └── StoreViewModel.swift     # Product loading
├── Services/
│   ├── StoreKitService.swift        # StoreKit 2 purchases
│   ├── FirebaseService.swift        # Auth, Firestore, Storage
│   ├── ExportService.swift          # Image flattening & sharing
│   └── AnalyticsService.swift       # Lightweight event tracking
├── Models/
│   ├── FilterItem.swift
│   ├── StickerPack.swift
│   ├── BananaPost.swift
│   └── UserProfile.swift
└── Resources/
    ├── Filters/                     # PNG overlays
    ├── Stickers/                    # Sticker assets
    └── Assets.xcassets
```

---

## Camera & Image Compositing

### Camera System

- Custom AVFoundation camera view
- No photo library read access (camera-only capture)
- Front/back camera toggle
- Basic flash support

### 3-Layer Compositing Model

```
┌─────────────────────────────┐
│  Layer 3: Stickers (top)    │  ← Transformable, z-ordered
├─────────────────────────────┤
│  Layer 2: Filter Overlay    │  ← Static PNG, full-frame
├─────────────────────────────┤
│  Layer 1: Base Photo        │  ← Captured banana image
└─────────────────────────────┘
```

### Export Logic

- Flatten layers using `UIGraphicsImageRenderer`
- Generate two outputs:
  - **Clean**: Full resolution, saved to camera roll, shared via iMessage
  - **Censored**: Gaussian blur center + watermark, for social feeds

---

## Editor State Management

```swift
class EditorViewModel: ObservableObject {
    @Published var baseImage: UIImage
    @Published var selectedFilter: FilterItem?
    @Published var stickers: [StickerState] = []

    private var undoStack: [EditorSnapshot] = []
    private var redoStack: [EditorSnapshot] = []
}

struct StickerState: Identifiable {
    let id: UUID
    let asset: StickerAsset
    var transform: StickerTransform  // position, scale, rotation
    var zIndex: Int
}
```

### Gesture Handling

Each sticker supports combined gestures:
- `DragGesture` → move position
- `MagnificationGesture` → pinch to scale
- `RotationGesture` → two-finger rotate
- Tap to select (shows delete button)

### Haptic "Vibe Check"

Intensity based on layer count, fires on sticker add, filter change, export.

---

## StoreKit 2 Integration

### Product Catalog

| Type | Price | Example IDs |
|------|-------|-------------|
| Filters | $1.99 | `filter.futuristic`, `filter.doctor`, `filter.party` |
| Sticker Packs | $0.99 | `stickers.fancy`, `stickers.food` |
| Unlimited Monthly | TBD | `unlimited.monthly` |
| Unlimited Annual | TBD | `unlimited.annual` |

### Entitlement Logic

1. Check `hasUnlimitedAccess` → unlocks everything
2. Otherwise check individual `purchasedProductIDs`
3. 3 filters always free (built-in)

### Secret Unlocks

Share counter stored in UserDefaults:
- 5 shares → unlock golden filter
- 10 shares → unlock rare sticker pack

---

## Firebase & Banana Showcase

### Firebase Services

- **Auth**: Anonymous by default, optional username upgrade
- **Firestore**: Posts, user profiles, reports
- **Storage**: Censored banana images

### Data Models

```swift
struct BananaPost: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let imageURL: String
    let filterUsed: String?
    let stickerCount: Int
    var upvotes: Int
    let createdAt: Date
    var isFeatured: Bool
}

struct UserProfile: Codable {
    @DocumentID var id: String?
    var username: String
    var totalUpvotes: Int
    var postCount: Int
    let createdAt: Date
}
```

### Showcase Features

- Feed: Paginated, sorted by recent or top
- Upvote: One per user per post
- Leaderboard: Top 10 by upvotes
- Featured: Daily top post
- Blur-to-view: Client-side, tap to reveal
- Report: Write to collection, manual review

---

## Safety & App Store

### Content Guardrails

| Safeguard | Implementation |
|-----------|----------------|
| Camera-only | No photo library read permission |
| Blur default | All Showcase images blurred until tap |
| Report flow | Flag → Firestore → manual review → remove |
| Onboarding | "Keep it campy, not explicit" shown before first post |
| Rate limiting | Firebase rules limit posts/day |

### Info.plist Keys

```xml
<key>NSCameraUsageDescription</key>
<string>Dickerator needs camera access to photograph your banana masterpiece.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your banana art to your camera roll.</string>
```

### App Store Review Note

> Dickerator is a campy, Gen Z-focused photo art app that transforms banana-shaped objects into shareable, absurd creations using curated filters and stickers.
>
> **Content positioning**: Playful novelty art tool, not adult content. Humor is suggestive and campy but never explicit.
>
> **Safety measures**: Camera-only capture (no library imports), blur-by-default on public feed, upvote-only engagement (no comments/DMs), user reporting with manual review, content guidelines shown during onboarding.
>
> **Target audience**: Gen Z and LGBTQ+ users who enjoy ironic internet humor and novelty apps.

---

## Analytics (Lightweight)

Track via simple event logging:
- Filter usage
- Sticker usage
- Share actions
- Conversion to paid content

No heavy frameworks - custom lightweight implementation.
