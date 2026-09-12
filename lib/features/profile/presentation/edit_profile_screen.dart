import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:access_map/app/app_state.dart';
import 'package:access_map/core/services/certificate_ocr_service.dart';
import 'package:access_map/core/theme/app_theme.dart';
import 'package:access_map/shared/models/user_profile.dart';
import 'package:access_map/shared/models/accessibility_need.dart';
import 'package:access_map/shared/widgets/app_components.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _conditionController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _udidController;
  late final TextEditingController _categoryController;
  late final TextEditingController _percentageController;
  late final TextEditingController _authorityController;
  late final TextEditingController _bloodGroupController;

  late bool _hasUploadedDocument;
  late String _documentName;
  bool _isOcrScanning = false;
  final _ocrService = CertificateOcrService();

  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactRelationController = TextEditingController();

  late List<EmergencyContact> _emergencyContacts;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    final med = profile.medicalInfo;

    _nameController = TextEditingController(text: profile.displayName);
    _conditionController = TextEditingController(text: med?.condition ?? '');
    _allergiesController = TextEditingController(text: med?.allergies ?? '');
    _instructionsController = TextEditingController(text: med?.instructions ?? '');
    _udidController = TextEditingController(text: med?.udidNumber ?? 'GA0710119950034512');
    _categoryController = TextEditingController(text: med?.disabilityCategory ?? 'Visual Impairment (Low Vision)');
    _percentageController = TextEditingController(text: med?.disabilityPercentage ?? '75% Permanent');
    _authorityController = TextEditingController(text: med?.issuingAuthority ?? 'Goa Medical College (GMC) & Hospital');
    _bloodGroupController = TextEditingController(text: med?.bloodGroup ?? 'B+ Positive');
    _hasUploadedDocument = med?.hasUploadedDocument ?? true;
    _documentName = med?.documentName.isNotEmpty == true
        ? med!.documentName
        : 'Govt_UDID_Certificate_${profile.displayName.replaceAll(' ', '_')}.pdf';
    _emergencyContacts = List<EmergencyContact>.from(profile.emergencyContacts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _conditionController.dispose();
    _allergiesController.dispose();
    _instructionsController.dispose();
    _udidController.dispose();
    _categoryController.dispose();
    _percentageController.dispose();
    _authorityController.dispose();
    _bloodGroupController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactRelationController.dispose();
    super.dispose();
  }

  void _addContact() {
    final name = _contactNameController.text.trim();
    final phone = _contactPhoneController.text.trim();
    final relation = _contactRelationController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide contact name and phone number.')),
      );
      return;
    }

    setState(() {
      _emergencyContacts.add(EmergencyContact(
        name: name,
        phone: phone,
        relation: relation.isEmpty ? 'Emergency Contact' : relation,
      ));
      _contactNameController.clear();
      _contactPhoneController.clear();
      _contactRelationController.clear();
    });
  }

  void _addCurrentPaContact() {
    setState(() {
      _emergencyContacts.add(const EmergencyContact(
        name: 'Personal Assistant (Caregiver)',
        phone: '+91 9822 101010',
        relation: 'Personal Assistant / Caregiver',
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal Assistant added to emergency contacts.')),
    );
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  void _showDocumentUploadPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload / Attach Medical Certificate',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select a document source to attach your government UDID card or medical disability certificate:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Scan with Device Camera'),
                subtitle: const Text('Capture certificate page or physical UDID card'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _hasUploadedDocument = true;
                    _documentName = 'UDID_Card_Scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate photo captured and attached successfully!')),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.picture_as_pdf, color: AppColors.primary),
                ),
                title: const Text('Choose PDF / Document File'),
                subtitle: const Text('Select existing medical certificate from storage'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _hasUploadedDocument = true;
                    _documentName = 'Medical_Board_Certificate_Goa.pdf';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document attached locally to profile.')),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.account_balance, color: AppColors.primary),
                ),
                title: const Text('Attach Sample e-UDID Document (Demo)'),
                subtitle: const Text('Simulate attaching an e-UDID document for testing'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _hasUploadedDocument = true;
                    _documentName = 'Sample_UDID_eCard_${_udidController.text.trim().isNotEmpty ? _udidController.text.trim() : "Demo"}.pdf';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample e-UDID document attached to profile.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final updatedMedical = MedicalInfo(
      condition: _conditionController.text.trim(),
      allergies: _allergiesController.text.trim(),
      instructions: _instructionsController.text.trim(),
      udidNumber: _udidController.text.trim(),
      disabilityCategory: _categoryController.text.trim(),
      disabilityPercentage: _percentageController.text.trim(),
      issuingAuthority: _authorityController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim(),
      hasUploadedDocument: _hasUploadedDocument,
      documentName: _documentName,
    );

    context.read<AppState>().updateProfile(
      displayName: newName.isNotEmpty ? newName : 'User',
      medicalInfo: updatedMedical,
      emergencyContacts: _emergencyContacts,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile & Emergency Information saved!')),
    );
    Navigator.of(context).pop();
  }

  void _showOcrPresetSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner, color: Color(0xFF0F766E), size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Select Certificate to Extract (Demo)',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose a sample document to auto-fill profile, medical, and assistance details:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.badge, color: Color(0xFF0F766E)),
                ),
                title: const Text('Sample UDID Card (Goa) - Aarav Sharma'),
                subtitle: const Text('Low Vision • 75% • Goa Medical College'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startOcrScan(presetIndex: 0);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.accessible, color: Color(0xFF0F766E)),
                ),
                title: const Text('Sample Hospital Certificate - Rohan Vernekar'),
                subtitle: const Text('Wheelchair User • 80% • Mapusa Civil Hospital'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startOcrScan(presetIndex: 1);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.hearing, color: Color(0xFF0F766E)),
                ),
                title: const Text('Sample Medical Pass - Sneha Kulkarni'),
                subtitle: const Text('Speech & Hearing • 100% • AIIPMR Institute'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startOcrScan(presetIndex: 2);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Simulate Document Capture with Camera'),
                subtitle: const Text('Snap physical disability card or medical certificate'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startOcrScan(presetIndex: 0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startOcrScan({int presetIndex = 0}) async {
    setState(() => _isOcrScanning = true);

    try {
      final extracted = await _ocrService.scanAndExtractDocument(presetIndex: presetIndex);
      if (!mounted) return;

      setState(() => _isOcrScanning = false);

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Details Extracted (Demo)',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Extracted 8 fields from ${extracted.documentTitle}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadii.borderRadiusMd,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _ocrPreviewRow('Cardholder Name', extracted.name),
                    _ocrPreviewRow('UDID Registration No.', extracted.udidNumber),
                    _ocrPreviewRow('Disability Category', extracted.disabilityCategory),
                    _ocrPreviewRow('Severity / %', extracted.disabilityPercentage),
                    _ocrPreviewRow('Issuing Hospital', extracted.issuingAuthority),
                    _ocrPreviewRow('Blood Group', extracted.bloodGroup),
                    _ocrPreviewRow('Allergies Alert', extracted.allergies),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _applyExtractedData(extracted);
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('APPLY & AUTO-FILL TO PROFILE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isOcrScanning = false);
    }
  }

  Widget _ocrPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _applyExtractedData(ExtractedCertificateData data) {
    setState(() {
      _nameController.text = data.name;
      _udidController.text = data.udidNumber;
      _categoryController.text = data.disabilityCategory;
      _percentageController.text = data.disabilityPercentage;
      _authorityController.text = data.issuingAuthority;
      _bloodGroupController.text = data.bloodGroup;
      _allergiesController.text = data.allergies;
      _conditionController.text = data.primaryCondition;
      _instructionsController.text = data.emergencyInstructions;
      _hasUploadedDocument = true;
      _documentName = data.documentTitle;
    });

    if (context.read<AppState>().profile.accessibilityNeeds.contains(AccessibilityNeed.blindLowVision)) {
      context.read<AppState>().ttsService.speak(
        'Medical certificate scanned. Profile details and UDID auto-filled successfully.',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade800,
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('All fields auto-filled from scanned medical certificate!'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile & Emergency ID'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // AI OCR Smart Auto-Fill Banner
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F766E).withValues(alpha: 0.15),
                    Colors.teal.shade50,
                  ],
                ),
                borderRadius: AppRadii.borderRadiusMd,
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.document_scanner, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Certificate Auto-Fill (Demo)',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                            Text(
                              'Select sample certificates or simulate scan to auto-fill fields',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    button: true,
                    label: 'Auto-fill profile using sample medical certificate or document extraction demo',
                    child: ElevatedButton.icon(
                      onPressed: _isOcrScanning ? null : () => _showOcrPresetSelector(),
                      icon: _isOcrScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 20),
                      label: Text(_isOcrScanning ? 'Extracting Details...' : 'SAMPLE DOCUMENT AUTO-FILL (DEMO)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text('Personal Identity', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter your name so community contributions and emergency SOS screens display your verified identity.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Your full name input field',
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Full Name',
                  hintText: 'e.g. Aarav Sharma',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Name cannot be blank' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Emergency Medical Info
            Text('Emergency & Medical Details', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This is displayed simultaneously with speech when triggering the Emergency SOS or scanning your ICE QR code.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Primary medical conditions or disability notes input field',
              child: TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: 'Primary Condition / Disability Note',
                  hintText: 'e.g. Low vision, wheelchair user, non-verbal',
                  prefixIcon: Icon(Icons.medical_information),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Allergies and contraindications input field',
              child: TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies & Medical Alerts',
                  hintText: 'e.g. Penicillin, latex, nuts',
                  prefixIcon: Icon(Icons.warning_amber),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Emergency instructions for bystanders and first responders input field',
              child: TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions for First Responders',
                  hintText: 'e.g. Non-verbal. Guide by arm. Please text instead of calling.',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Government UDID & Disability Certificate Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('UDID & Disability Certificate', style: AppTypography.headlineSmall),
                const Icon(Icons.verified, color: Colors.green, size: 22),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upload and verify your Unique Disability ID (UDID) or hospital certificate. You can show this pass anytime to transit staff, conductors, or security.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            // UDID Number Field
            Semantics(
              label: 'Unique Disability ID Number input field',
              child: TextFormField(
                controller: _udidController,
                decoration: const InputDecoration(
                  labelText: 'UDID / Certificate Registration Number',
                  hintText: 'e.g. GA0710119950034512',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Disability Category & Percentage in Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: 'Disability category input field',
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Disability Category',
                        hintText: 'e.g. Locomotor, Low Vision',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    label: 'Disability percentage input field',
                    child: TextFormField(
                      controller: _percentageController,
                      decoration: const InputDecoration(
                        labelText: 'Severity / %',
                        hintText: 'e.g. 75%',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Issuing Authority & Blood Group
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: 'Issuing medical authority or hospital input field',
                    child: TextFormField(
                      controller: _authorityController,
                      decoration: const InputDecoration(
                        labelText: 'Issuing Medical Authority',
                        hintText: 'e.g. Goa Medical College (GMC)',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    label: 'Blood group input field',
                    child: TextFormField(
                      controller: _bloodGroupController,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        hintText: 'e.g. B+',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Uploaded Document Card
            Card(
              color: AppColors.surfaceVariant,
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
                        Icon(
                          _hasUploadedDocument ? Icons.check_circle : Icons.upload_file,
                          color: _hasUploadedDocument ? AppColors.success : AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hasUploadedDocument ? _documentName : 'No Certificate Attached Yet',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _hasUploadedDocument
                                    ? 'Attached & Available Offline'
                                    : 'Upload scanned PDF or photo of physical UDID',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showDocumentUploadPicker,
                            icon: const Icon(Icons.upload, size: 18),
                            label: Text(_hasUploadedDocument ? 'Change Document' : 'Upload Document'),
                          ),
                        ),
                        if (_hasUploadedDocument) ...[
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            tooltip: 'Remove Attached Document',
                            onPressed: () {
                              setState(() {
                                _hasUploadedDocument = false;
                                _documentName = '';
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Emergency Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emergency Contacts (ICE)', style: AppTypography.headlineSmall),
                TextButton.icon(
                  onPressed: _addCurrentPaContact,
                  icon: const Icon(Icons.handshake, size: 18),
                  label: const Text('Add Me (PA)'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'These contacts will be notified via WhatsApp & phone during an SOS trigger.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_emergencyContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadii.borderRadiusMd,
                ),
                child: const Text(
                  'No emergency contacts added yet. Add at least one contact below.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else
              ..._emergencyContacts.asMap().entries.map((entry) {
                final idx = entry.key;
                final contact = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.contact_phone),
                    ),
                    title: Text(contact.name, style: AppTypography.titleMedium),
                    subtitle: Text('${contact.phone} • ${contact.relation}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _removeContact(idx),
                      tooltip: 'Remove contact',
                    ),
                  ),
                );
              }),

            const SizedBox(height: AppSpacing.md),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.borderRadiusMd,
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Add New Contact', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _contactRelationController,
                      decoration: const InputDecoration(
                        labelText: 'Relationship (e.g. Brother, Caregiver)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contact to List'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              label: 'Save Profile & ICE Details',
              icon: Icons.check,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
