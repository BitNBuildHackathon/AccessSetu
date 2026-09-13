import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/features/profile/presentation/edit_profile_screen.dart';

/// Full-screen digital disability pass and medical certificate viewer
/// Designed for easy 1-tap presentation to transit conductors, station staff,
/// airline personnel, hospital triage, and security guards.
class DisabilityPassScreen extends StatefulWidget {
  const DisabilityPassScreen({super.key});

  @override
  State<DisabilityPassScreen> createState() => _DisabilityPassScreenState();
}

class _DisabilityPassScreenState extends State<DisabilityPassScreen> {
  bool _highContrastMode = false;

  void _speakPassDetails(BuildContext context) {
    final state = context.read<AppState>();
    final profile = state.profile;
    final med = profile.medicalInfo;

    final udid = med?.udidNumber.isNotEmpty == true ? med!.udidNumber : 'Not registered';
    final category = med?.disabilityCategory.isNotEmpty == true
        ? med!.disabilityCategory
        : (med?.condition.isNotEmpty == true ? med!.condition : 'Disability assistance required');
    final percent = med?.disabilityPercentage.isNotEmpty == true
        ? ', ${med!.disabilityPercentage}'
        : '';
    final authority = med?.issuingAuthority.isNotEmpty == true
        ? ' Issued by ${med!.issuingAuthority}.'
        : '';
    final emergency = profile.emergencyContacts.isNotEmpty
        ? ' Emergency contact: ${profile.emergencyContacts.first.name} at ${profile.emergencyContacts.first.phone}.'
        : '';

    final spokenText =
        'Accessibility Assistance ID Card for ${profile.displayName}. '
        'Registration or U D I D number: $udid. '
        'Category: $category$percent.$authority$emergency';

    state.ttsService.speak(spokenText);
  }

  void _openDocumentPreview(BuildContext context, String docName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                docName.isNotEmpty ? docName : 'Official Medical Certificate',
                style: AppTypography.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: AppRadii.borderRadiusSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Stored Medical Certificate (Self-Uploaded Document)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Simulated Certificate Sheet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: AppRadii.borderRadiusMd,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance, size: 36, color: Color(0xFF0D47A1)),
                    const SizedBox(height: 4),
                    const Text(
                      'GOVERNMENT OF INDIA\nDEPARTMENT OF EMPOWERMENT OF PERSONS WITH DISABILITIES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 16),
                    const Text(
                      'CERTIFICATE OF DISABILITY & MEDICAL ID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This certifies that the holder has undergone medical examination and is diagnosed with the documented disability condition per the Rights of Persons with Disabilities Act, 2016.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('SEAL & STAMP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Icon(Icons.verified_user, color: Colors.blue, size: 28),
                            ],
                          ),
                          Column(
                            children: [
                              Text('MEDICAL SUPERINTENDENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Icon(Icons.draw, color: Colors.black54, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final med = profile.medicalInfo;

    final udid = med?.udidNumber.isNotEmpty == true ? med!.udidNumber : 'GA0710119950034512';
    final category = med?.disabilityCategory.isNotEmpty == true
        ? med!.disabilityCategory
        : (med?.condition.isNotEmpty == true ? med!.condition : 'Locomotor / Mobility Assistance');
    final percentage = med?.disabilityPercentage.isNotEmpty == true
        ? med!.disabilityPercentage
        : '75% Permanent';
    final authority = med?.issuingAuthority.isNotEmpty == true
        ? med!.issuingAuthority
        : 'Goa Medical College (GMC) & Hospital, Bambolim';
    final issueDate = med?.issueDate.isNotEmpty == true ? med!.issueDate : '12/03/2023';
    final bloodGroup = med?.bloodGroup.isNotEmpty == true ? med!.bloodGroup : 'B+ Positive';
    final hasDoc = med?.hasUploadedDocument ?? true;
    final docName = med?.documentName.isNotEmpty == true
        ? med!.documentName
        : 'Govt_UDID_Certificate_${profile.displayName.replaceAll(' ', '_')}.pdf';

    // QR payload for offline digital verification
    final qrPayload = jsonEncode({
      'issuer': 'AccessSetu Self-Declared Profile',
      'name': profile.displayName,
      'udid': udid,
      'category': category,
      'percentage': percentage,
      'authority': authority,
      'date': issueDate,
      'blood': bloodGroup,
      'contacts': profile.emergencyContacts.map((c) => {'n': c.name, 'p': c.phone}).toList(),
    });

    final cardBgColor = _highContrastMode ? Colors.black : Colors.white;
    final cardTextColor = _highContrastMode ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: _highContrastMode ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Disability Pass (Self-Declared)'),
        actions: [
          IconButton(
            icon: Icon(_highContrastMode ? Icons.wb_sunny : Icons.wb_sunny_outlined),
            tooltip: _highContrastMode ? 'Normal Contrast' : 'Outdoor High Contrast Boost',
            onPressed: () => setState(() => _highContrastMode = !_highContrastMode),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Read Out Pass Credentials',
            onPressed: () => _speakPassDetails(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Pass Details & Uploads',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EditProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Info banner for user
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadii.borderRadiusMd,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Present this pass to conductors, transit staff, security, or airline assistance for instant verification.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ==========================================
            // MAIN OFFICIAL PASS CARD
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _highContrastMode ? Colors.amberAccent : AppColors.divider,
                  width: _highContrastMode ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _highContrastMode ? Colors.transparent : Colors.black12,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pass Card Top Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      gradient: _highContrastMode
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.primaryDark, AppColors.primary],
                            ),
                      color: _highContrastMode ? Colors.amberAccent : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.badge,
                          color: _highContrastMode ? Colors.black : Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACCESSIBILITY ASSISTANCE PASS',
                                style: TextStyle(
                                  color: _highContrastMode ? Colors.black : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'UNIQUE DISABILITY ID (UDID)',
                                style: TextStyle(
                                  color: _highContrastMode ? Colors.black : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _highContrastMode
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: _highContrastMode ? Colors.amberAccent : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'DOC ON FILE',
                                style: TextStyle(
                                  color: _highContrastMode ? Colors.amberAccent : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cardholder Details Section
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: _highContrastMode ? Colors.amberAccent : AppColors.primarySurface,
                              foregroundColor: _highContrastMode ? Colors.black : AppColors.primary,
                              child: Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName.substring(0, 1).toUpperCase()
                                    : 'A',
                                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Name & Registration
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: TextStyle(
                                      color: cardTextColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'UDID No: $udid',
                                    style: TextStyle(
                                      color: _highContrastMode ? Colors.amberAccent : AppColors.primaryDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _highContrastMode ? Colors.white12 : AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _highContrastMode ? Colors.white24 : AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          'Blood: $bloodGroup',
                                          style: TextStyle(
                                            color: _highContrastMode ? Colors.white : AppColors.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _highContrastMode ? Colors.amber.withValues(alpha: 0.2) : AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          percentage,
                                          style: TextStyle(
                                            color: _highContrastMode ? Colors.amberAccent : AppColors.primaryDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Key Medical / Disability Table
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: _highContrastMode ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceVariant,
                            borderRadius: AppRadii.borderRadiusMd,
                            border: Border.all(color: _highContrastMode ? Colors.white12 : AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              _PassRow(
                                label: 'Disability / Need',
                                value: category,
                                isHighContrast: _highContrastMode,
                              ),
                              Divider(color: _highContrastMode ? Colors.white12 : AppColors.divider, height: 16),
                              _PassRow(
                                label: 'Issuing Authority',
                                value: authority,
                                isHighContrast: _highContrastMode,
                              ),
                              Divider(color: _highContrastMode ? Colors.white12 : AppColors.divider, height: 16),
                              _PassRow(
                                label: 'Issue Date',
                                value: issueDate,
                                isHighContrast: _highContrastMode,
                              ),
                              if (med?.allergies.isNotEmpty == true) ...[
                                Divider(color: _highContrastMode ? Colors.white12 : AppColors.divider, height: 16),
                                _PassRow(
                                  label: 'Allergies',
                                  value: med!.allergies,
                                  isHighContrast: _highContrastMode,
                                  valueColor: AppColors.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // QR Code for Instant Inspector Verification
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _highContrastMode ? Colors.amberAccent : AppColors.divider,
                                width: _highContrastMode ? 2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan to verify credentials & view emergency contact details offline',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _highContrastMode ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Bar of Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: _highContrastMode ? Colors.black45 : AppColors.primarySurface,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACCESSSETU SECURE PASS',
                          style: TextStyle(
                            color: _highContrastMode ? Colors.white54 : AppColors.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: _highContrastMode ? Colors.greenAccent : AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'OFFLINE ID',
                              style: TextStyle(
                                color: _highContrastMode ? Colors.greenAccent : AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ==========================================
            // ATTACHED MEDICAL CERTIFICATE / DOCUMENT
            // ==========================================
            Text(
              'Attached Medical Certificate / Scans',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.borderRadiusMd,
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: AppRadii.borderRadiusSm,
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                docName,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasDoc ? 'Uploaded & Stored Locally (Offline)' : 'No document file attached',
                                style: AppTypography.bodySmall.copyWith(
                                  color: hasDoc ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDocumentPreview(context, docName),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Doc', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Upload / Edit', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Emergency Contacts Quick Display
            if (profile.emergencyContacts.isNotEmpty) ...[
              Text(
                'Designated Emergency Contacts',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...profile.emergencyContacts.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.phone, color: AppColors.primary),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.relation} • ${c.phone}'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  const _PassRow({
    required this.label,
    required this.value,
    required this.isHighContrast,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isHighContrast;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: isHighContrast ? Colors.amberAccent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isHighContrast ? Colors.white : AppColors.textPrimary),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
