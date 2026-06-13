import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../models/device.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  DeviceType _type = DeviceType.light;
  String _room = 'Sala';
  double _maxValue = 100;

  final List<String> _rooms = ['Sala', 'Dormitorio', 'Cocina', 'Entrada', 'Exterior', 'General'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _topicCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar Dispositivo',
          style: TextStyle(
            fontFamily: AppTheme.fontName,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppTheme.darkText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tipo de dispositivo'),
              const SizedBox(height: 12),
              _buildTypeGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Nombre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('Ej: Lámpara Escritorio'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Habitación'),
              const SizedBox(height: 8),
              _buildRoomChips(),
              if (_type == DeviceType.temperature) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('Ciudad'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: _inputDecoration('Ej: Buenos Aires, Madrid...'),
                ),
              ],
              const SizedBox(height: 20),
              _buildSectionTitle('Topic MQTT (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _topicCtrl,
                decoration: _inputDecoration(
                  'Default: ${_type.mqttTopic}',
                  helperText: 'Dejar vacío para usar el topic por defecto',
                ),
              ),
              const SizedBox(height: 20),
              if (_type.hasSlider) ...[
                _buildSectionTitle('Valor máximo'),
                const SizedBox(height: 8),
                _buildMaxValueSlider(),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Agregar dispositivo',
                    style: TextStyle(
                      fontFamily: AppTheme.fontName,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.fontName,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppTheme.darkText,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? helperText}) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      filled: true,
      fillColor: AppTheme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTypeGrid() {
    final types = DeviceType.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final selected = _type == t;
        return GestureDetector(
          onTap: () => setState(() => _type = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? t.color.withValues(alpha: 0.15) : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? t.color : AppTheme.deactivatedText.withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(t.icon, size: 16, color: selected ? t.color : AppTheme.deactivatedText),
                const SizedBox(width: 8),
                Text(
                  t.label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? t.color : AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoomChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _rooms.map((r) {
        final selected = _room == r;
        return GestureDetector(
          onTap: () => setState(() => _room = r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryAccent : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppTheme.primaryAccent : AppTheme.deactivatedText.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              r,
              style: TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: selected ? Colors.white : AppTheme.darkText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaxValueSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_maxValue.toInt()}',
              style: const TextStyle(
                fontFamily: AppTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxValue,
          min: 1,
          max: 1000,
          divisions: 20,
          onChanged: (v) => setState(() => _maxValue = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: TextStyle(fontSize: 11, color: AppTheme.deactivatedText)),
            Text('1000', style: TextStyle(fontSize: 11, color: AppTheme.deactivatedText)),
          ],
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final id = '${_type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final device = Device(
      id: id,
      name: _nameCtrl.text.trim(),
      type: _type,
      room: _room,
      city: _cityCtrl.text.trim(),
      customTopic: _topicCtrl.text.trim(),
      maxValue: _maxValue,
    );

    Navigator.pop(context, device);
  }
}
