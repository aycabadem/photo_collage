import 'package:flutter/material.dart';
import '../models/background.dart';

class IOSColorPickerModal extends StatefulWidget {
  final Color currentColor;
  final double currentOpacity;
  final Function(Color color, double opacity) onColorChanged;
  final BackgroundMode initialMode;
  final GradientSpec? initialGradient;
  final void Function(GradientSpec spec, double opacity)? onGradientChanged;

  const IOSColorPickerModal({
    super.key,
    required this.currentColor,
    required this.currentOpacity,
    required this.onColorChanged,
    this.initialMode = BackgroundMode.solid,
    this.initialGradient,
    this.onGradientChanged,
  });

  @override
  State<IOSColorPickerModal> createState() => _IOSColorPickerModalState();
}

class _IOSColorPickerModalState extends State<IOSColorPickerModal> {
  late Color _selectedColor;
  late double _selectedOpacity;
  late BackgroundMode _mode;
  late GradientSpec _gradient;
  late double _h; // 0..360
  late double _s; // 0..1
  late double _l; // 0..1
  // Gradient A/B editing (compact, two-color)
  late Color _gA;
  late Color _gB;
  bool _activeA = true; // which chip is active for HSL edits
  late double _gH, _gS, _gL; // working HSL for active chip

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
    _selectedOpacity = widget.currentOpacity;
    _mode = widget.initialMode;
    _gradient = widget.initialGradient ?? GradientSpec.presetPinkPurple();
    final hsl = HSLColor.fromColor(_selectedColor);
    _h = hsl.hue;
    _s = 1.0; // Start Saturation slider at max by default
    _l = hsl.lightness;
    // İlk açılışta mevcut rengi aynen koru; otomatik doygunluk/aydınlık ayarı yapma.

    // Initialize gradient A/B from current gradient spec (first/last stops)
    if (_gradient.stops.length >= 2) {
      _gA = _gradient.stops.first.color;
      _gB = _gradient.stops.last.color;
    } else {
      _gA = Colors.pink;
      _gB = Colors.purple;
    }
    _loadActiveStopHsl(fromA: _activeA);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      constraints: BoxConstraints(maxHeight: size.height * 0.34),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeTabs(),
          const SizedBox(height: 4),
          _mode == BackgroundMode.solid
              ? _buildHslControls()
              : _buildGradientTwoColorCompact(),
        ],
      ),
    );
  }

  // Header removed for compact design

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _tab('Color', _mode == BackgroundMode.solid, () {
            setState(() => _mode = BackgroundMode.solid);
            // Apply current solid as live preview
            widget.onColorChanged(_selectedColor, _selectedOpacity);
          }),
          const SizedBox(width: 8),
          _tab('Gradient', _mode == BackgroundMode.gradient, () {
            setState(() => _mode = BackgroundMode.gradient);
            // Apply current gradient as live preview
            if (widget.onGradientChanged != null) {
              widget.onGradientChanged!(_gradient, _selectedOpacity);
            }
          }),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.30)
                : Theme.of(context).colorScheme.primary.withOpacity(0.20),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    // Replaced by HSL sliders. Keep method for compatibility if referenced.
    return _buildHslControls();
  }

  Widget _buildHslControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _hueSlider(),
          const SizedBox(height: 8),
          _saturationSlider(),
          const SizedBox(height: 8),
          _lightnessSlider(),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _resetToWhite,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToWhite() {
    setState(() {
      _mode = BackgroundMode.solid;
      _selectedColor = Colors.white;
      _selectedOpacity = 1.0;
      final hsl = HSLColor.fromColor(_selectedColor);
      _h = hsl.hue;
      _s = 0.0;
      _l = hsl.lightness;
    });
    widget.onColorChanged(_selectedColor, _selectedOpacity);
  }

  Widget _hueSlider() {
    final colors = [
      for (int i = 0; i <= 12; i++)
        HSLColor.fromAHSL(1.0, i * 30.0, 1.0, 0.5).toColor(),
    ];
    return _gradientLineSlider(
      label: 'H',
      valueLabel: '${_h.round()}°',
      colors: colors,
      min: 0,
      max: 360,
      value: _h,
      onChanged: (v) {
        setState(() => _h = v);
        _applyHslLive();
      },
      divisions: 360,
      snapToEnds: true,
    );
  }

  Widget _saturationSlider() {
    final c0 = HSLColor.fromAHSL(1.0, _h, 0.0, _l).toColor();
    final c1 = HSLColor.fromAHSL(1.0, _h, 1.0, _l).toColor();
    return _gradientLineSlider(
      label: 'S',
      valueLabel: '${(_s * 100).round()}%',
      colors: [c0, c1],
      min: 0,
      max: 1,
      value: _s,
      onChanged: (v) {
        setState(() => _s = v);
        _applyHslLive();
      },
      divisions: 100,
      snapToEnds: true,
    );
  }

  Widget _lightnessSlider() {
    final mid = HSLColor.fromAHSL(1.0, _h, _s, 0.5).toColor();
    return _gradientLineSlider(
      label: 'L',
      valueLabel: '${(_l * 100).round()}%',
      colors: [Colors.black, mid, Colors.white],
      min: 0,
      max: 1,
      value: _l,
      onChanged: (v) {
        setState(() => _l = v);
        _applyHslLive();
      },
      divisions: 100,
      snapToEnds: true,
    );
  }

  Widget _gradientLineSlider({
    required String label,
    required String valueLabel,
    required List<Color> colors,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
    int? divisions,
    bool snapToEnds = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  min: min,
                  max: max,
                  value: value,
                  divisions: divisions,
                  onChanged: onChanged,
                  onChangeEnd: (v) {
                    if (!snapToEnds) return;
                    final thr = (max - min) * 0.02; // 2% snapping
                    double snapped = v;
                    if ((v - min).abs() <= thr) snapped = min;
                    if ((max - v).abs() <= thr) snapped = max;
                    if (snapped != v) onChanged(snapped);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyHslLive() {
    final c = HSLColor.fromAHSL(1.0, _h, _s, _l).toColor();
    _selectedColor = c;
    if (_mode == BackgroundMode.solid) {
      widget.onColorChanged(_selectedColor, _selectedOpacity);
    }
  }

  Widget _buildOpacitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact: remove label to save space
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _selectedOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _selectedOpacity = value;
                      });
                      // Live preview: apply immediately without closing
                      if (_mode == BackgroundMode.solid) {
                        widget.onColorChanged(_selectedColor, _selectedOpacity);
                      } else if (widget.onGradientChanged != null) {
                        widget.onGradientChanged!(_gradient, _selectedOpacity);
                      }
                    },
                  ),
                ),
              ),
              Container(
                width: 52,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.30),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(_selectedOpacity * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedColorPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Text(
            'SELECTED COLOR',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: _selectedOpacity),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _generateColorGrid() {
    final colors = <Color>[];

    // First row: Grays
    for (int i = 0; i < 12; i++) {
      final grayValue = (255 * (i / 11)).round();
      colors.add(Color.fromRGBO(grayValue, grayValue, grayValue, 1));
    }

    // Next 6 rows: Color spectrum
    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 12; col++) {
        final hue = (col / 11) * 360;
        final saturation = 0.3 + (row / 5) * 0.7;
        final lightness = 0.2 + (row / 5) * 0.6;

        colors.add(
          HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor(),
        );
      }
    }

    return colors;
  }

  Widget _buildGradientCompact() {
    return Column(
      children: [
        // Presets row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _gradientPresetChip(GradientSpec.presetPinkPurple()),
              _gradientPresetChip(GradientSpec.presetTealBlue()),
              _gradientPresetChip(GradientSpec.presetSunset()),
              _gradientPresetChip(GradientSpec.presetLime()),
            ],
          ),
        ),
        // Angle slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              const Text('ANGLE', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _gradient.angleDeg,
                  min: 0,
                  max: 360,
                  divisions: 36,
                  onChanged: (v) {
                    setState(() => _gradient = _gradient.copyWith(angleDeg: v));
                    if (widget.onGradientChanged != null) {
                      widget.onGradientChanged!(_gradient, _selectedOpacity);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New compact two‑color gradient editor (keeps presets + adds A/B chips + H/S sliders)
  Widget _buildGradientTwoColorCompact() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A/B chips + preview + swap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _colorChip(_gA, _activeA, 'A', () {
                setState(() => _activeA = true);
                _loadActiveStopHsl(fromA: true);
              }),
              const SizedBox(width: 8),
              _colorChip(_gB, !_activeA, 'B', () {
                setState(() => _activeA = false);
                _loadActiveStopHsl(fromA: false);
              }),
              const SizedBox(width: 12),
              // Preview bar
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [_gA, _gB],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _swapAB,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    ),
                  ),
                  child: const Icon(Icons.swap_horiz, size: 18),
                ),
              ),
            ],
          ),
        ),

        // Compact H + S + L sliders for active stop
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: _gradientHueSlider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: _gradientSatSlider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: _gradientLightSlider(),
        ),

        // Angle slider styled like H/S/L
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: _angleSlider(),
        ),
      ],
    );
  }

  Widget _colorChip(Color c, bool active, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.50)
                : Theme.of(context).colorScheme.primary.withOpacity(0.25),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientHueSlider() {
    final colors = [
      for (int i = 0; i <= 12; i++)
        HSLColor.fromAHSL(1.0, i * 30.0, 1.0, 0.5).toColor(),
    ];
    return _gradientLineSlider(
      label: _activeA ? 'H (A)' : 'H (B)',
      valueLabel: '${_gH.round()}°',
      colors: colors,
      min: 0,
      max: 360,
      value: _gH,
      onChanged: (v) {
        setState(() => _gH = v);
        _commitActiveHsl();
      },
      divisions: 360,
      snapToEnds: true,
    );
  }

  Widget _gradientSatSlider() {
    final c0 = HSLColor.fromAHSL(1.0, _gH, 0.0, _gL).toColor();
    final c1 = HSLColor.fromAHSL(1.0, _gH, 1.0, _gL).toColor();
    return _gradientLineSlider(
      label: _activeA ? 'S (A)' : 'S (B)',
      valueLabel: '${(_gS * 100).round()}%',
      colors: [c0, c1],
      min: 0,
      max: 1,
      value: _gS,
      onChanged: (v) {
        setState(() => _gS = v);
        _commitActiveHsl();
      },
      divisions: 100,
      snapToEnds: true,
    );
  }

  Widget _gradientLightSlider() {
    final mid = HSLColor.fromAHSL(1.0, _gH, _gS, 0.5).toColor();
    return _gradientLineSlider(
      label: _activeA ? 'L (A)' : 'L (B)',
      valueLabel: '${(_gL * 100).round()}%',
      colors: [Colors.black, mid, Colors.white],
      min: 0,
      max: 1,
      value: _gL,
      onChanged: (v) {
        setState(() => _gL = v);
        _commitActiveHsl();
      },
      divisions: 100,
      snapToEnds: true,
    );
  }

  Widget _angleSlider() {
    // Subtle grey gradient as track styling
    return _gradientLineSlider(
      label: 'ANGLE',
      valueLabel: '${_gradient.angleDeg.round()}°',
      colors: const [Color(0xFFE0E0E0), Color(0xFF757575)],
      min: 0,
      max: 360,
      value: _gradient.angleDeg,
      onChanged: (v) {
        setState(() => _gradient = _gradient.copyWith(angleDeg: v));
        _applyGradientLive();
      },
      divisions: 360,
      snapToEnds: true,
    );
  }

  void _swapAB() {
    setState(() {
      final tmp = _gA;
      _gA = _gB;
      _gB = tmp;
      _activeA = !_activeA; // keep editing the same visual end
    });
    _applyGradientLive();
  }

  void _loadActiveStopHsl({required bool fromA}) {
    final c = fromA ? _gA : _gB;
    final hsl = HSLColor.fromColor(c);
    _gH = hsl.hue;
    _gS = hsl.saturation < 0.6 ? 0.9 : hsl.saturation;
    _gL = (hsl.lightness > 0.85 || hsl.lightness < 0.15) ? 0.5 : hsl.lightness;
  }

  void _commitActiveHsl() {
    final c = HSLColor.fromAHSL(1.0, _gH, _gS, _gL).toColor();
    setState(() {
      if (_activeA) {
        _gA = c;
      } else {
        _gB = c;
      }
    });
    _applyGradientLive();
  }

  void _applyGradientLive() {
    _gradient = GradientSpec(
      stops: [
        GradientStop(offset: 0.0, color: _gA),
        GradientStop(offset: 1.0, color: _gB),
      ],
      angleDeg: _gradient.angleDeg,
    );
    if (widget.onGradientChanged != null) {
      widget.onGradientChanged!(_gradient, _selectedOpacity);
    }
  }

  Widget _gradientPresetChip(GradientSpec spec) {
    return GestureDetector(
      onTap: () {
        setState(() => _gradient = spec);
        if (widget.onGradientChanged != null) {
          widget.onGradientChanged!(spec, _selectedOpacity);
        }
      },
      child: Container(
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: spec.stops.map((s) => s.color).toList(),
            stops: spec.stops.map((s) => s.offset).toList(),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.20),
          ),
        ),
      ),
    );
  }
}
