import QtQuick

// ─────────────────────────────────────────────
//  Theme.qml  –  design tokens
//  Place at: ~/.config/quickshell/Theme.qml
//
//  Usage from any sibling/child component:
//    Theme { id: theme }
//    color: theme.archBlue
// ─────────────────────────────────────────────

QtObject {
    id: root

    // ── Arch palette ──────────────────────────────────────────────────

    // Primary accents
    readonly property color archBlue:     "#1793d1"   // official Arch blue
    readonly property color archCyan:     "#00b4d8"   // lighter cyan accent
    readonly property color archDim:      "#0077b6"   // darker blue for borders/pressed

    // Backgrounds  (dark, layered)
    readonly property color bgBar:        "#0d1117"   // bar surface
    readonly property color bgSurface:    "#161b22"   // pill / widget surface
    readonly property color bgHover:      "#1c2433"   // hover state
    readonly property color bgActive:     "#1a2a3a"   // active/pressed
    readonly property color bgOverlay:    "#21262d"   // popups, tooltips

    // Text
    readonly property color textPrimary:  "#e6edf3"   // main readable text
    readonly property color textMuted:    "#7d8590"   // secondary labels
    readonly property color textDim:      "#484f58"   // disabled / placeholder
    readonly property color textAccent:   archCyan    // highlighted values

    // Borders
    readonly property color border:       Qt.rgba(0.09, 0.58, 0.82, 0.18)   // subtle blue-tinted
    readonly property color borderHover:  Qt.rgba(0.09, 0.58, 0.82, 0.45)   // on hover
    readonly property color borderActive: archBlue                           // focused/active

    // Special
    readonly property color glowLine:     Qt.rgba(0.09, 0.58, 0.82, 0.25)   // shimmer line
    readonly property color shimmerL:     archBlue                           // left shimmer stop
    readonly property color shimmerR:     archCyan                           // right shimmer stop

    // Semantic (battery low, etc.)
    readonly property color warning:      "#e6a817"   // amber — battery ≤ 20%
    readonly property color danger:       "#f85149"   // red   — battery ≤ 5%, high CPU
    readonly property color success:      "#3fb950"   // green — charging, connected

    // ── Bar geometry ─────────────────────────────────────────────────

    readonly property int barHeight:      44     // total bar height in px
    readonly property int barPadding:     12     // left/right inner padding
    readonly property int barMargin:      0      // outer margin (0 = full-width, 8 = floating)
    readonly property int barRadius:      0      // corner radius (0 = full-width, 12 = floating pill)

    // ── Spacing & sizing ─────────────────────────────────────────────

    readonly property int gap:            6      // standard gap between bar sections
    readonly property int gapSm:          3      // tight gap (workspace pills)
    readonly property int gapLg:          10     // loose gap (inside pills)
    readonly property int pillPaddingH:   10     // pill horizontal padding
    readonly property int pillPaddingV:   4      // pill vertical padding
    readonly property int pillRadius:     20     // pill border-radius
    readonly property int widgetRadius:   8      // non-pill widget corners
    readonly property int sepWidth:       1      // separator width
    readonly property int sepHeight:      16     // separator height

    // Workspace pills
    readonly property int wsWidth:        28
    readonly property int wsHeight:       24
    readonly property int wsRadius:       6

    // Mini progress bars (CPU/RAM)
    readonly property int miniBarWidth:   30
    readonly property int miniBarHeight:  4
    readonly property int miniBarRadius:  2

    // Battery icon
    readonly property int batWidth:       18
    readonly property int batHeight:      11
    readonly property int batRadius:      2
    readonly property int batTipWidth:    3
    readonly property int batTipHeight:   5

    // ── Typography ───────────────────────────────────────────────────

    readonly property string fontFamily:  "monospace"  // swap for "JetBrains Mono" if installed
    readonly property int    fontSm:      10     // date, sub-labels, wifi name
    readonly property int    fontBase:    11     // pill values, workspace numbers
    readonly property int    fontMd:      12     // media title
    readonly property int    fontLg:      14     // clock time
    readonly property int    weightNormal: Font.Normal   // 400
    readonly property int    weightMed:   Font.Medium    // 500

    // ── Animation ────────────────────────────────────────────────────

    // All durations in ms — keep these consistent across modules
    readonly property int animDuration:   320    // bar slide-in, major transitions
    readonly property int animFast:       150    // hover state changes
    readonly property int animMed:        250    // value number updates, pill expand
    readonly property int animSlow:       600    // progress bar fill transitions

    // Easing types (reference these by name in NumberAnimation)
    // OutCubic  → standard smooth decel  (most transitions)
    // OutBack   → slight overshoot       (workspace pill scale)
    // InOutSine → gentle s-curve         (brightness/battery bar)

    // ── Module update intervals (ms) ─────────────────────────────────

    readonly property int clockInterval:  1000   // 1s — clock tick
    readonly property int statsInterval:  2000   // 2s — CPU / RAM
    readonly property int battInterval:   5000   // 5s — battery level
    readonly property int brightInterval: 500    // 0.5s — brightness (fast for scroll feel)
    readonly property int netInterval:    5000   // 5s — network signal

    // ── Brightness ───────────────────────────────────────────────────

    // Device name — must match output of: ls /sys/class/backlight/
    // Common values: "intel_backlight", "amdgpu_bl1", "acpi_video0"
    readonly property string backlightDevice: "intel_backlight"

    // Step size for scroll-wheel brightness adjustment
    readonly property int brightStep:     5      // percent per scroll tick

    // ── Battery thresholds ───────────────────────────────────────────

    readonly property int batWarnLevel:   20     // % → switch to warning color
    readonly property int batCritLevel:   5      // % → switch to danger color

    // ── Media ────────────────────────────────────────────────────────

    readonly property int mediaTitleMax:  18     // chars before marquee scrolls
    readonly property int mediaMarqueeMs: 4000   // scroll cycle duration

    // ── CPU / RAM display ─────────────────────────────────────────────

    // RAM display unit: "GB" shows e.g. "5.2G", "percent" shows e.g. "52%"
    readonly property string ramUnit:    "GB"

    // ── Helper functions ─────────────────────────────────────────────

    // Returns the right color for a battery level
    function batteryColor(level) {
        if (level <= batCritLevel)  return danger
        if (level <= batWarnLevel)  return warning
        return archCyan
    }

    // Returns the right color for CPU usage
    function cpuColor(percent) {
        if (percent >= 90) return danger
        if (percent >= 70) return warning
        return archCyan
    }

    // Clamps a value between min and max
    function clamp(val, lo, hi) {
        return Math.max(lo, Math.min(hi, val))
    }

    // Formats RAM bytes → "5.2G" or "812M"
    function formatRam(bytes) {
        var gb = bytes / (1024 * 1024 * 1024)
        if (gb >= 1.0) return gb.toFixed(1) + "G"
        var mb = bytes / (1024 * 1024)
        return Math.round(mb) + "M"
    }
}
