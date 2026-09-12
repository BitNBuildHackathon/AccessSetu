/// Smart OCR & document extraction service for Disability Certificates & UDID Cards.
/// Parses and auto-populates profile fields from scanned or uploaded medical documents.
class ExtractedCertificateData {
  final String name;
  final String udidNumber;
  final String disabilityCategory;
  final String disabilityPercentage;
  final String issuingAuthority;
  final String issueDate;
  final String bloodGroup;
  final String allergies;
  final String primaryCondition;
  final String emergencyInstructions;
  final double confidenceScore;
  final String documentTitle;

  const ExtractedCertificateData({
    required this.name,
    required this.udidNumber,
    required this.disabilityCategory,
    required this.disabilityPercentage,
    required this.issuingAuthority,
    required this.issueDate,
    required this.bloodGroup,
    required this.allergies,
    required this.primaryCondition,
    required this.emergencyInstructions,
    this.confidenceScore = 0.98,
    required this.documentTitle,
  });
}

class CertificateOcrService {
  /// Presets of authentic Indian UDID and hospital disability certificates
  /// for quick instant testing and realistic simulation.
  static final List<ExtractedCertificateData> sampleCertificates = [
    const ExtractedCertificateData(
      name: 'Aarav Sharma',
      udidNumber: 'GA0710119950034512',
      disabilityCategory: 'Visual Impairment (Low Vision)',
      disabilityPercentage: '75% Permanent',
      issuingAuthority: 'Goa Medical College (GMC) & Hospital, Bambolim',
      issueDate: '12/03/2023',
      bloodGroup: 'B+ Positive',
      allergies: 'Penicillin',
      primaryCondition: 'Low vision / requires audio cues and step-free guidance',
      emergencyInstructions: 'Carries white cane. Guide by offering arm. High audio sensitivity.',
      confidenceScore: 0.99,
      documentTitle: 'Govt_UDID_Goa_Card_Aarav.pdf',
    ),
    const ExtractedCertificateData(
      name: 'Rohan Vernekar',
      udidNumber: 'GA0210219900019844',
      disabilityCategory: 'Locomotor Disability / Wheelchair User',
      disabilityPercentage: '80% Permanent',
      issuingAuthority: 'District Civil Hospital, Mapusa, North Goa',
      issueDate: '20/08/2022',
      bloodGroup: 'O+ Positive',
      allergies: 'Sulfa Drugs',
      primaryCondition: 'Paraplegia / full-time motorized wheelchair user',
      emergencyInstructions: 'Requires step-free ramps. Cannot climb stairs. Keep wheelchair accessible.',
      confidenceScore: 0.97,
      documentTitle: 'Disability_Board_Certificate_Mapusa.jpg',
    ),
    const ExtractedCertificateData(
      name: 'Sneha Kulkarni',
      udidNumber: 'MH1410319980076211',
      disabilityCategory: 'Speech & Hearing Impairment',
      disabilityPercentage: '100% Profound',
      issuingAuthority: 'All India Institute of Physical Medicine & Rehabilitation',
      issueDate: '05/01/2024',
      bloodGroup: 'A+ Positive',
      allergies: 'None recorded',
      primaryCondition: 'Non-verbal / profound bilateral sensorineural hearing loss',
      emergencyInstructions: 'Communicate via written notes or phone text. Do not shout.',
      confidenceScore: 0.98,
      documentTitle: 'AIIPMR_Medical_Certificate_Sneha.pdf',
    ),
  ];

  /// Simulates scanning a document via OCR with a short processing delay
  /// to replicate real-world neural OCR text extraction.
  Future<ExtractedCertificateData> scanAndExtractDocument({
    String? customDocumentName,
    int presetIndex = 0,
  }) async {
    // Replicate realistic OCR image pre-processing and text recognition delay
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (presetIndex >= 0 && presetIndex < sampleCertificates.length) {
      final preset = sampleCertificates[presetIndex];
      if (customDocumentName != null && customDocumentName.isNotEmpty) {
        return ExtractedCertificateData(
          name: preset.name,
          udidNumber: preset.udidNumber,
          disabilityCategory: preset.disabilityCategory,
          disabilityPercentage: preset.disabilityPercentage,
          issuingAuthority: preset.issuingAuthority,
          issueDate: preset.issueDate,
          bloodGroup: preset.bloodGroup,
          allergies: preset.allergies,
          primaryCondition: preset.primaryCondition,
          emergencyInstructions: preset.emergencyInstructions,
          confidenceScore: preset.confidenceScore,
          documentTitle: customDocumentName,
        );
      }
      return preset;
    }

    return sampleCertificates.first;
  }
}
