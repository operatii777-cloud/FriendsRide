enum DriverDocumentType {
  profilePhoto,
  idCard,
  drivingLicenseFront,
  drivingLicenseBack,
  carExterior,
  carInsurance,
  criminalRecord,
  transportAttestation,
}

extension DriverDocumentTypeExtension on DriverDocumentType {
  String get displayName {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'Poză de Profil';
      case DriverDocumentType.idCard:
        return 'Carte de Identitate';
      case DriverDocumentType.drivingLicenseFront:
        return 'Permis de Conducere (față)';
      case DriverDocumentType.drivingLicenseBack:
        return 'Permis de Conducere (verso)';
      case DriverDocumentType.carExterior:
        return 'Poză Mașină (exterior)';
      case DriverDocumentType.carInsurance:
        return 'Asigurare RCA';
      case DriverDocumentType.criminalRecord:
        return 'Cazier Judiciar';
      case DriverDocumentType.transportAttestation:
        return 'Atestat Transport Persoane';
    }
  }
  
  String get storageFolder {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'profile_photos';
      case DriverDocumentType.idCard:
        return 'id_cards';
      case DriverDocumentType.drivingLicenseFront:
        return 'driving_licenses_front';
      case DriverDocumentType.drivingLicenseBack:
        return 'driving_licenses_back';
      case DriverDocumentType.carExterior:
        return 'car_photos';
      case DriverDocumentType.carInsurance:
        return 'car_insurance';
      case DriverDocumentType.criminalRecord:
        return 'criminal_records';
      case DriverDocumentType.transportAttestation:
        return 'transport_attestations';
    }
  }
  
  String get firestoreField {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'profilePhotoUrl';
      case DriverDocumentType.idCard:
        return 'idCardUrl';
      case DriverDocumentType.drivingLicenseFront:
        return 'drivingLicenseFrontUrl';
      case DriverDocumentType.drivingLicenseBack:
        return 'drivingLicenseBackUrl';
      case DriverDocumentType.carExterior:
        return 'carExteriorUrl';
      case DriverDocumentType.carInsurance:
        return 'carInsuranceUrl';
      case DriverDocumentType.criminalRecord:
        return 'criminalRecordUrl';
      case DriverDocumentType.transportAttestation:
        return 'transportAttestationUrl';
    }
  }
  
  String get description {
    switch (this) {
      case DriverDocumentType.profilePhoto:
        return 'Fotografie recentă pentru profilul dvs.';
      case DriverDocumentType.idCard:
        return 'Carte de identitate română valabilă';
      case DriverDocumentType.drivingLicenseFront:
        return 'Partea din față a permisului de conducere';
      case DriverDocumentType.drivingLicenseBack:
        return 'Partea din spate a permisului de conducere';
      case DriverDocumentType.carExterior:
        return 'Fotografie cu mașina din exterior';
      case DriverDocumentType.carInsurance:
        return 'Certificat de asigurare RCA valabil';
      case DriverDocumentType.criminalRecord:
        return 'Cazier judiciar emis în ultimele 3 luni';
      case DriverDocumentType.transportAttestation:
        return 'Atestat pentru transportul de persoane';
    }
  }
  
  bool get isRequired {
    switch (this) {
      case DriverDocumentType.profilePhoto:
      case DriverDocumentType.idCard:
      case DriverDocumentType.drivingLicenseFront:
      case DriverDocumentType.drivingLicenseBack:
      case DriverDocumentType.carExterior:
      case DriverDocumentType.carInsurance:
        return true;
      case DriverDocumentType.criminalRecord:
      case DriverDocumentType.transportAttestation:
        return false; // Opționale sau depind de localitate
    }
  }
}

class DriverDocument {
  final DriverDocumentType type;
  final String? url;
  final DateTime? uploadedAt;
  final String? fileName;
  final bool isUploaded;

  DriverDocument({
    required this.type,
    this.url,
    this.uploadedAt,
    this.fileName,
    this.isUploaded = false,
  });

  factory DriverDocument.fromFirestore(DriverDocumentType type, Map<String, dynamic>? data) {
    if (data == null) {
      return DriverDocument(type: type);
    }
    
    return DriverDocument(
      type: type,
      url: data[type.firestoreField],
      uploadedAt: data['${type.firestoreField}_uploadedAt']?.toDate(),
      fileName: data['${type.firestoreField}_fileName'],
      isUploaded: data[type.firestoreField] != null,
    );
  }

  DriverDocument copyWith({
    String? url,
    DateTime? uploadedAt,
    String? fileName,
    bool? isUploaded,
  }) {
    return DriverDocument(
      type: type,
      url: url ?? this.url,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileName: fileName ?? this.fileName,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}

class DriverApplicationData {
  final String? fullName;
  final String? age;
  final String? carBrand;
  final String? carModel;
  final String? carColor;
  final String? carYear;
  final String? licensePlate;
  final String? bankAccount;
  final Map<DriverDocumentType, DriverDocument> documents;
  final DateTime? submittedAt;
  final String status; // 'draft', 'submitted', 'under_review', 'approved', 'rejected'

  DriverApplicationData({
    this.fullName,
    this.age,
    this.carBrand,
    this.carModel,
    this.carColor,
    this.carYear,
    this.licensePlate,
    this.bankAccount,
    this.documents = const {},
    this.submittedAt,
    this.status = 'draft',
  });

  factory DriverApplicationData.fromFirestore(Map<String, dynamic> data) {
    final documents = <DriverDocumentType, DriverDocument>{};
    
    for (final docType in DriverDocumentType.values) {
      documents[docType] = DriverDocument.fromFirestore(docType, data);
    }
    
    return DriverApplicationData(
      fullName: data['fullName'],
      age: data['age'],
      carBrand: data['carBrand'],
      carModel: data['carModel'],
      carColor: data['carColor'],
      carYear: data['carYear'],
      licensePlate: data['licensePlate'],
      bankAccount: data['bankAccount'],
      documents: documents,
      submittedAt: data['submittedAt']?.toDate(),
      status: data['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'fullName': fullName,
      'age': age,
      'carBrand': carBrand,
      'carModel': carModel,
      'carColor': carColor,
      'carYear': carYear,
      'licensePlate': licensePlate,
      'bankAccount': bankAccount,
      'status': status,
      'submittedAt': submittedAt,
    };

    // Adaugă documentele
    for (final entry in documents.entries) {
      final docType = entry.key;
      final document = entry.value;
      
      if (document.isUploaded) {
        data[docType.firestoreField] = document.url;
        data['${docType.firestoreField}_uploadedAt'] = document.uploadedAt;
        data['${docType.firestoreField}_fileName'] = document.fileName;
      }
    }

    return data;
  }

  bool get isComplete {
    // Verifică dacă toate documentele obligatorii sunt încărcate
    final requiredDocs = DriverDocumentType.values.where((doc) => doc.isRequired);
    return requiredDocs.every((docType) => documents[docType]?.isUploaded == true) &&
           fullName != null && fullName!.isNotEmpty &&
           age != null && age!.isNotEmpty &&
           carBrand != null && carBrand!.isNotEmpty &&
           carModel != null && carModel!.isNotEmpty &&
           licensePlate != null && licensePlate!.isNotEmpty;
  }

  double get completionPercentage {
    final totalRequired = DriverDocumentType.values.where((doc) => doc.isRequired).length + 5; // +5 pentru câmpurile obligatorii
    int completed = 0;

    // Verifică documentele obligatorii
    final requiredDocs = DriverDocumentType.values.where((doc) => doc.isRequired);
    for (final docType in requiredDocs) {
      if (documents[docType]?.isUploaded == true) completed++;
    }

    // Verifică câmpurile obligatorii
    if (fullName != null && fullName!.isNotEmpty) completed++;
    if (age != null && age!.isNotEmpty) completed++;
    if (carBrand != null && carBrand!.isNotEmpty) completed++;
    if (carModel != null && carModel!.isNotEmpty) completed++;
    if (licensePlate != null && licensePlate!.isNotEmpty) completed++;

    return completed / totalRequired;
  }
}