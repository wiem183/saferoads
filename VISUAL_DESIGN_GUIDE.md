# Scanned Amende Display - Visual Design Guide

## Screen Layout Overview

### Full Screen Structure

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ← Scanned Amende                   ┃  ← App Bar (Color-coded)
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                                     ┃
┃        [VIOLATION ICON]             ┃  ← Colored Header
┃        SPEEDING                     ┃     (Red, Orange, Blue, etc.)
┃                                     ┃
┃    ┌──────────────────────┐        ┃
┃    │    150 DT            │        ┃  ← Amount Box
┃    └──────────────────────┘        ┃
┃                                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  📍 Location                        ┃
┃     Avenue Mohamed V, Tunis         ┃  ← Detail Sections
┃                                     ┃     (Scrollable)
┃  👤 Violator ID                     ┃
┃     user_12345                      ┃
┃                                     ┃
┃  🛡️  Agent ID                       ┃
┃     agent_789                       ┃
┃                                     ┃
┃  🏷️  Amende ID              [Copy]  ┃
┃     amende_xyz_123                  ┃
┃                                     ┃
┃  Evidence Photo                     ┃
┃  ┌──────────────────────────────┐  ┃
┃  │    [Photo with shadow]       │  ┃
┃  │    300px height              │  ┃
┃  │    Full width                │  ┃
┃  └──────────────────────────────┘  ┃
┃                                     ┃
┃  ┌──────────────────────────────┐  ┃
┃  │  ✓ Got It                    │  ┃
┃  └──────────────────────────────┘  ┃
┃                                     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Color Codes by Violation Type

### Speeding Violation (Red)
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ← Scanned Amende      [Red App Bar]┃
┃                                     ┃
┃  [Red background header]            ┃
┃        ⚡                           ┃
┃      SPEEDING                       ┃
┃                                     ┃
┃    ┌──────────────────────┐        ┃
┃    │  150 DT  [Red tone]  │        ┃
┃    └──────────────────────┘        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Parking Violation (Orange)
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ← Scanned Amende   [Orange App Bar]┃
┃                                     ┃
┃  [Orange background header]         ┃
┃        🅿️                          ┃
┃      PARKING VIOLATION              ┃
┃                                     ┃
┃    ┌──────────────────────┐        ┃
┃    │  75 DT [Orange tone] │        ┃
┃    └──────────────────────┘        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Detail Card Design

```
Single Detail Card:

┌────────────────────────────────────────┐
│  ┌──────┐                              │
│  │  📍  │  Location                    │  ← Icon with color
│  │  Red │  (Label - small grey text)   │
│  └──────┘                              │
│         Avenue Mohamed V, Tunis        │  ← Value (large, bold)
│                                        │
└────────────────────────────────────────┘

Icon Box: 12px padding, color-coded
Icon Size: 24px
Icon Colors:
  - 📍 Red (#FF5252) for Location
  - 👤 Blue (#2196F3) for Person
  - 🛡️  Green (#4CAF50) for Agent
  - 🏷️  Purple (#9C27B0) for ID
  - 🚗 Orange (#FF9800) for Details
```

## Header Variations

### Red Header (Speeding/Red Light)
```
Height: 200px
Background: Red gradient or solid
┌─────────────────────────────┐
│                             │
│      ⚡ (64px icon)         │
│                             │
│      SPEEDING               │  Font: 28px bold
│                             │
│   ┌─────────────────────┐  │
│   │   150 DT            │  │  Transparent white box
│   │  (32px bold)        │  │
│   └─────────────────────┘  │
│                             │
└─────────────────────────────┘
Bottom corners: 24px radius
```

### Orange Header (Parking)
```
Same structure with orange background
┌─────────────────────────────┐
│                             │
│     🅿️ (64px icon)          │
│                             │
│   PARKING VIOLATION         │
│                             │
│   ┌─────────────────────┐  │
│   │   75 DT             │  │
│   └─────────────────────┘  │
│                             │
└─────────────────────────────┘
```

## Photo Display States

### Loading State
```
┌──────────────────────────────┐
│  Evidence Photo              │
│  ┌────────────────────────┐  │
│  │   [Spinner]            │  │  300px height
│  │   Loading...           │  │  Centered
│  │                        │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

### Success State
```
┌──────────────────────────────┐
│  Evidence Photo              │
│  ┌────────────────────────┐  │
│  │                        │  │
│  │    [Real Photo]        │  │  300px height
│  │    Full width          │  │  Cover fit
│  │    Rounded corners     │  │  Shadow effect
│  │    Box shadow effect   │  │
│  │                        │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

### Error State
```
┌──────────────────────────────┐
│  Evidence Photo              │
│  ┌────────────────────────┐  │
│  │  📷                    │  │  300px height
│  │  Photo not available   │  │  Grey background
│  │                        │  │  Icon + message
│  └────────────────────────┘  │
└──────────────────────────────┘
```

## Button Design

### "Got It" Button
```
Full Width at bottom:

┌──────────────────────────────┐
│  ✓ Got It                    │
└──────────────────────────────┘

Properties:
- Width: Match parent
- Height: 48px
- Background: Green (#4CAF50)
- Icon: check_circle (24px)
- Text: 16px bold
- Corner radius: 8px
- Padding: 12px vertical
```

## Spacing Reference

```
Top padding of header: 24px
Icon size: 64px
Gap between icon and title: 16px
Title to amount box: 16px
Amount box to details: 16px + 8px gap

Each detail section padding: 16px
Gap between details: 12px

Photo label to image: 12px
Image to button: 24px

Button padding: 12px vertical
```

## Typography

```
App Bar Title: 16px, Medium weight
Header Title: 28px, Bold weight
Amount: 32px, Bold weight
Detail Label: 12px, Regular, Color: Grey
Detail Value: 16px, Semi-bold, Color: Black87
Photo Label: 14px, Medium weight
Button Text: 16px, Medium weight
```

## Icon Mapping Chart

| Element | Icon | Color | Size |
|---------|------|-------|------|
| Speeding | ⚡ | Red | 64px (header), 24px (detail) |
| Parking | 🅿️ | Orange | 64px, 24px |
| Red Light | 🚦 | Red | 64px, 24px |
| Seat Belt | 🏎️ | Blue | 64px, 24px |
| Phone Use | 📱 | Purple | 64px, 24px |
| Documentary | 📄 | Brown | 64px, 24px |
| Other | ℹ️ | Grey | 64px, 24px |
| Location | 📍 | Red | 24px |
| Violator | 👤 | Blue | 24px |
| Agent | 🛡️ | Green | 24px |
| ID | 🏷️ | Purple | 24px |

## Responsive Behavior

### Mobile (< 600px)
- Header height: 200px
- Full-width details
- Single column layout
- Touch-friendly buttons (48px)

### Tablet (600px - 900px)
- Header height: 220px
- Larger icons (72px)
- More padding
- Wider detail cards

### Desktop (> 900px)
- Header height: 240px
- Max-width container (600px)
- Centered on screen
- Large text

## Accessibility Features

✅ Large font sizes (minimum 16px)
✅ High contrast colors
✅ Clear icon-text pairing
✅ Adequate spacing (12px+ between elements)
✅ Selectable text for copying
✅ Loading indicators
✅ Error messages
✅ 48px minimum touch targets
✅ Color not only means (icons + text)
✅ Proper semantic structure

## Animation States

- Header fades in with color
- Details fade in sequentially
- Photo loads with fade-in
- Button has tap feedback
- Smooth transitions (200-300ms)
