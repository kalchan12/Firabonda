# Design System: Fira Bonda

## 1. Design direction

Modern, **Gen Z** style: clean, bold, playful but not childish. Dark blue is the primary identity. There is a full light mode as well.

Keywords: rounded, spacious, confident numbers, smooth motion.

## 2. Theme modes

- Dark, Light, System. Default: **Dark**.
- Selection is saved and restored on launch.

## 3. Color tokens

| Token | Dark | Light |
|-------|------|-------|
| background | `#0B1020` | `#F6F8FC` |
| surface | `#121A33` | `#FFFFFF` |
| surfaceVariant | `#1A2547` | `#EAEFFA` |
| primary (electric blue) | `#3D6BFF` | `#2F5BFF` |
| onPrimary | `#FFFFFF` | `#FFFFFF` |
| textPrimary | `#F2F5FF` | `#0B1020` |
| textMuted | `#8A96B8` | `#5B6788` |
| profit (green) | `#2ECC8F` | `#14A56E` |
| loss / spent (red) | `#FF5C7A` | `#E0405E` |
| warning (amber) | `#FFB84D` | `#E59A1F` |
| border | `#232F55` | `#D9E0F2` |

Define all colors as theme tokens in one file. Never hardcode colors inside widgets.

## 4. Typography

- Modern bundled fonts (offline first): **Sora** for headings, screen titles, and big money numbers; **Inter** for body text and labels.
- Scale: Display 34/bold (big money numbers), Title 22/bold, Heading 18/semibold, Body 15/regular, Label 12/medium (muted).
- Money values always use tabular figures via `FontFeature.tabularFigures()`, so numbers and prices align vertically.

## 5. Shape, spacing, elevation

- Corner radius: cards 24, buttons 16, chips 999 (pill), bottom sheets 28 top corners.
- Spacing scale: 4, 8, 12, 16, 20, 24, 32.
- Screen padding: 20.
- Touch targets: minimum 52dp on all primary action buttons, inputs, and touchable cards.
- Prefer subtle borders and soft shadows over heavy shadows. Light gradients allowed on hero cards.
- Glass/blur effect only for the floating nav bar and speed-dial overlay backdrop, never behind long text.

## 6. Navigation

Floating bottom dock with 4 destinations and a prominent 68-72dp raised circular center button:

1. Home (dashboard)
2. Purchases
3. **+ Batch Purchase** (center, raised 20dp, accent blue glow, cutout notch) -> opens Batch purchase directly with zero delay (Fix Plan V2.1 Task 3).
4. Sales
5. More

## 7. Core screens

1. **Dashboard**: period selector (Today / Yesterday / Week / Month / All / Custom), Net Profit hero tile with status badge, 2x2 grid (Sold, Cost of sold, Bought, Expenses), Target Profit gauge (100% default), recent sales in period, and expandable "More details" accordion (stock value, low stock alerts, best sellers, profit curve chart).
2. **Purchases list**: grouped by date, search bar, filter chips, each card shows category icon, color dot, quantity, unit cost, stock left.
3. **Add / edit purchase**: category chips, color chips, quantity stepper with +1/+5/+10 quick chips, unit cost with last price hint, 100% target profit prefill helper, smart category/supplier defaults.
4. **Batch purchase**: bundle lot entry with total cost, supplier, account, and dynamic items list with Hamilton largest-remainder exact cost allocation.
5. **Quick sale & Sell sheet**: 2-3 tap selling flow, 100% target profit prefill, partial payment support with automatic debt receivable generation.
6. **Stock adjustments**: record damaged, lost, returned, personal use, or count corrections with live cost and stock deduction.
7. **Reconciliation & Day close**: expected vs counted cash and stock comparison with discrepancy tracking; day close summary with one-tap clipboard report export.
8. **More**: suppliers, expenses, debts, categories & colors, stock adjustments, reconciliation, day close, export, backup, settings.
9. **Quick calculator**: app-shell floating trigger button, 20-entry calculation history, clipboard copy, and "Use result" action.

## 7.1 Mini calculator behavior

- Opens as a bottom sheet from the calculator icon inside any money field.
- Keys: 0-9, `.`, `+ - x /`, `%`, clear, backspace.
- Starts with the current field value if there is one.
- "Use result" writes the value back and closes. Invalid expressions show a gentle error, never crash.

## 8. Motion

- Page transitions: 250 to 300 ms, ease-out.
- Animated number counters on the dashboard.
- Button press scale feedback (0.97).
- Light haptic on: save, sold, delete confirm.
- Respect the system "reduce motion" setting.

## 9. Responsive and flexible layout

- No fixed pixel layouts. Use `LayoutBuilder`, `Flexible`, `Expanded`, `Wrap`.
- Must work on small phones (360 dp wide) up to tablets, portrait and landscape.
- Must work with large system text sizes without overflow.
- Test with text scale 1.0, 1.3 and 1.6.

## 10. Empty, loading and error states

- Every list has a friendly empty state (icon, one short line, one action button).
- Loading uses skeleton shimmers, not spinners alone.
- Errors use a calm message and a retry action. Never show raw exceptions.

## 11. Accessibility

- Contrast ratio at least 4.5:1 for text in both themes.
- Tap targets at least 48x48 dp.
- Semantic labels on icon-only buttons.
- Never rely on color alone: profit and loss also use +/- signs and arrows.

## 12. Tone of voice

Short, friendly, simple English. Example: "No purchases yet. Add your first one." Avoid accounting jargon.
