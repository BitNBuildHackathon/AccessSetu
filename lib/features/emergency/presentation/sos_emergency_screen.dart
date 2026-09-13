import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:access_map/features/profile/presentation/disability_pass_screen.dart';
import 'dart:convert';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  bool _isSpeaking = false;
  bool _showQr = false;
  int _countdown = 3;
  bool _countdownActive = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted || !_countdownActive) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted && _countdownActive) {
      setState(() => _countdownActive = false);
      _startSosSequence();
    }
  }

  @override
  void deactivate() {
    _countdownActive = false;
    context.read<AppState>().ttsService.stop();
    super.deactivate();
  }

  Future<void> _startSosSequence() async {
    final state = context.read<AppState>();
    setState(() => _isSpeaking = true);
    
    // TTS must fire <1s according to system prompt (6.5)
    final msg = _buildSosMessage(state.profile.medicalInfo);
    
    // Force speak even if they don't have blind needs, because SOS might be triggered by Can't Speak
    await state.ttsService.speak(msg, force: true);
    
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  String _buildSosMessage(MedicalInfo? info) {
    String msg = "Emergency assistance requested. ";
    if (info != null) {
      if (info.condition.isNotEmpty) {
        msg += "I have ${info.condition}. ";
      }
      if (info.instructions.isNotEmpty) {
        msg += "${info.instructions}. ";
      }
    }
    return msg;
  }

  void _callContact(EmergencyContact contact) async {
    final url = Uri.parse('tel:${contact.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _messageWhatsApp(EmergencyContact contact) async {
    final url = Uri.parse('https://wa.me/${contact.phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=Emergency!%20I%20need%20help.%20Please%20contact%20me%20immediately.');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    final msg = _buildSosMessage(profile.medicalInfo);

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('EMERGENCY SOS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Text Summary (Crucial for Deaf Users - Prompt 6.5)
              Semantics(
                header: true,
                child: Text(
                  msg,
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isSpeaking)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: 32),
                    SizedBox(width: AppSpacing.md),
                    Text('Broadcasting audio...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              
              if (_showQr) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: jsonEncode({
                        'name': profile.displayName,
                        'condition': profile.medicalInfo?.condition,
                        'allergies': profile.medicalInfo?.allergies,
                        'instructions': profile.medicalInfo?.instructions,
                        'contacts': profile.emergencyContacts.map((c) => {'n': c.name, 'p': c.phone}).toList(),
                      }),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              
              if (_countdownActive) ...[
                const SizedBox(height: AppSpacing.xl),
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'SOS triggering in $_countdown...',
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
                // Semantic Focus Order required by Prompt 6.5
                // 1. Contacts
                if (profile.emergencyContacts.isNotEmpty) ...[
                  Semantics(
                    button: true,
                    label: "Call Primary Emergency Contact, ${profile.emergencyContacts.first.name}",
                    child: ElevatedButton.icon(
                      onPressed: () => _callContact(profile.emergencyContacts.first),
                      icon: const Icon(Icons.phone),
                      label: Flexible(
                        child: Text(
                          'CALL ${profile.emergencyContacts.first.name.toUpperCase()}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 2. WhatsApp
                  Semantics(
                    button: true,
                    label: "Message Primary Emergency Contact on WhatsApp",
                    child: ElevatedButton.icon(
                      onPressed: () => _messageWhatsApp(profile.emergencyContacts.first),
                      icon: const Icon(Icons.message),
                      label: const Text('WHATSAPP CONTACT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ] else ...[
                  Semantics(
                    button: true,
                    label: "Call Local Emergency Services 112",
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('tel:112');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      icon: const Icon(Icons.local_hospital),
                      label: const Text('CALL 112 (EMERGENCY)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppSpacing.md),
                
                // 3. ICE QR
                Semantics(
                  button: true,
                  label: _showQr ? "Hide ICE QR Code" : "Show ICE QR Code for bystanders to scan",
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showQr = !_showQr),
                    icon: const Icon(Icons.qr_code),
                    label: Text(_showQr ? 'HIDE EMERGENCY ID' : 'SHOW EMERGENCY ID (QR)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // 3b. Full Disability Pass & Medical Certificate
                Semantics(
                  button: true,
                  label: "Show Official Disability Pass and Medical Certificate to Paramedics or Officials",
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DisabilityPassScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.badge, color: Colors.amberAccent),
                    label: const Flexible(
                      child: Text(
                        'SHOW OFFICIAL UDID / MEDICAL PASS',
                        style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],

              // Emergency Liability & Assistance Notice
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: AppRadii.borderRadiusMd,
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Emergency Aid Notice: This broadcast communicates medical needs for non-verbal or distressed individuals. Bystanders: please render first aid and dial 112 directly.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              
              // 4. Cancel
              Semantics(
                button: true,
                label: "Cancel SOS Emergency and return to map",
                child: TextButton(
                  onPressed: () {
                    _countdownActive = false;
                    context.read<AppState>().ttsService.stop();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text('CANCEL SOS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
