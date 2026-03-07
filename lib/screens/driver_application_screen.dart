import 'dart:io';
import 'package:flutter/material.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:friendsride_app/models/driver_document_model.dart';
import 'package:friendsride_app/services/driver_application_service.dart';
import 'package:friendsride_app/utils/logger.dart';
import 'package:friendsride_app/widgets/driver_document_status_widget.dart';
import 'package:intl/intl.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  State<DriverApplicationScreen> createState() => _DriverApplicationScreenState();
}

/// Document types that commonly carry an expiry date.
const _expiryDocTypes = {
  DriverDocumentType.drivingLicenseFront,
  DriverDocumentType.drivingLicenseBack,
  DriverDocumentType.carInsurance,
  DriverDocumentType.criminalRecord,
  DriverDocumentType.transportAttestation,
  DriverDocumentType.idCard,
};

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  int _currentStep = 0;
  final DriverApplicationService _applicationService = DriverApplicationService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Controllers pentru formulare
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _carBrandController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  
  // State management
  DriverApplicationData? _currentApplication;
  bool _isLoading = false;
  final Map<DriverDocumentType, bool> _uploadingStatus = {};
  // Tracks locally-chosen expiry dates before upload completes
  final Map<DriverDocumentType, DateTime> _pendingExpiryDates = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentApplication();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _carBrandController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    _carYearController.dispose();
    _licensePlateController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentApplication() async {
    setState(() => _isLoading = true);
    
    try {
      final application = await _applicationService.getCurrentApplication();
      if (application != null) {
        setState(() {
          _currentApplication = application;
          _populateControllers(application);
        });
      } else {
        setState(() {
          _currentApplication = DriverApplicationData();
        });
      }
    } catch (e) {
      Logger.error('Error loading application: $e', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.applicationLoadError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers(DriverApplicationData application) {
    _fullNameController.text = application.fullName ?? '';
    _ageController.text = application.age ?? '';
    _carBrandController.text = application.carBrand ?? '';
    _carModelController.text = application.carModel ?? '';
    _carColorController.text = application.carColor ?? '';
    _carYearController.text = application.carYear ?? '';
    _licensePlateController.text = application.licensePlate ?? '';
    _bankAccountController.text = application.bankAccount ?? '';
  }

  Future<void> _uploadDocument(DriverDocumentType documentType) async {
    setState(() => _uploadingStatus[documentType] = true);

    try {
      // Afișează opțiunile de selecție
      final source = await _showImageSourceDialog();
      if (source == null) return;

      File? fileToUpload;
      String fileName = '';

      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        
        if (image != null) {
          fileToUpload = File(image.path);
          fileName = image.name;
        }
      } else {
        // Pentru galerie, permite și PDF
        final fileType = await _showFileTypeDialog();
        if (fileType == null) return;

        if (fileType == 'image') {
          final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          
          if (image != null) {
            fileToUpload = File(image.path);
            fileName = image.name;
          }
        } else {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );

          if (result != null && result.files.isNotEmpty) {
            fileToUpload = File(result.files.first.path!);
            fileName = result.files.first.name;
          }
        }
      }

      if (fileToUpload == null) return;

      // Optionally pick an expiry date for documents that may expire
      final expiryDate = await _showExpiryDateDialog(documentType);
      if (expiryDate != null) {
        _pendingExpiryDates[documentType] = expiryDate;
      }

      // Upload documentul
      await _applicationService.uploadDocument(
        documentType: documentType,
        file: fileToUpload,
        fileName: fileName,
      );

      // Save expiry date if the user provided one
      if (_pendingExpiryDates.containsKey(documentType)) {
        await _applicationService.setDocumentExpiryDate(
          documentType,
          _pendingExpiryDates[documentType]!,
        );
        _pendingExpiryDates.remove(documentType);
      }

      // Actualizează aplicația locală
      await _loadCurrentApplication();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.documentUploadSuccess(documentType.displayName)),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      Logger.error('Error uploading document: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.documentUploadError(_getErrorMessage(e))),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingStatus[documentType] = false);
      }
    }
  }

  Future<void> _removeDocument(DriverDocumentType documentType) async {
    try {
      await _applicationService.removeDocument(documentType);
      await _loadCurrentApplication();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.documentDeleteSuccess(documentType.displayName)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.documentDeleteError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectSourceTitle),
          content: Text(AppLocalizations.of(context)!.selectSourceContent),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(AppLocalizations.of(context)!.cameraOption),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(AppLocalizations.of(context)!.galleryOption),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showFileTypeDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectFileTypeTitle),
        content: Text(AppLocalizations.of(context)!.selectFileTypeContent),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'image'),
            icon: const Icon(Icons.image),
            label: Text(AppLocalizations.of(context)!.imageOption),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'pdf'),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(AppLocalizations.of(context)!.pdfOption),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  /// Shows a date picker for optionally setting an expiry date on a document.
  /// Returns null if the user skips or dismisses.
  Future<DateTime?> _showExpiryDateDialog(DriverDocumentType documentType) async {
    if (!_expiryDocTypes.contains(documentType)) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.expiryDateTitle),
        content: Text(AppLocalizations.of(context)!.expiryDateQuestion(documentType.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.skipExpiry),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return null;

    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: AppLocalizations.of(context)!.selectExpiryDate,
    );
  }

  void _viewDocument(DriverDocumentType documentType) {
    final documentUrl = _applicationService.getDocumentUrl(_currentApplication!, documentType);
    if (documentUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(documentType.displayName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Flexible(
              child: InteractiveViewer(
                child: documentUrl.endsWith('.pdf')
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.pdfDocument),
                              SizedBox(height: 8),
                              Text(AppLocalizations.of(context)!.tapToOpen, style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : Image.network(
                        documentUrl,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text(AppLocalizations.of(context)!.errorLoadingImage),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDocumentOptions(DriverDocumentType documentType) {
    final isUploaded = _applicationService.isDocumentUploaded(_currentApplication!, documentType);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)!.photographOption),
                onTap: () {
                  Navigator.pop(context);
                  _uploadDocument(documentType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.selectFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _uploadDocument(documentType);
                },
              ),
              if (isUploaded)
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text(AppLocalizations.of(context)!.viewDocumentOption),
                  onTap: () {
                    Navigator.pop(context);
                    _viewDocument(documentType);
                  },
                ),
              if (isUploaded)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.deleteDocumentOption, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeDocument(documentType);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text(AppLocalizations.of(context)!.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveCurrentStep() async {
    setState(() => _isLoading = true);

    try {
      switch (_currentStep) {
        case 0:
          await _applicationService.savePersonalInfo(
            fullName: _fullNameController.text.trim(),
            age: _ageController.text.trim(),
          );
          break;
        case 1:
          await _applicationService.saveCarInfo(
            carBrand: _carBrandController.text.trim(),
            carModel: _carModelController.text.trim(),
            carColor: _carColorController.text.trim(),
            carYear: _carYearController.text.trim(),
            licensePlate: _licensePlateController.text.trim(),
          );
          break;
        case 2:
          await _applicationService.saveFinalInfo(
            bankAccount: _bankAccountController.text.trim(),
          );
          break;
      }

      await _loadCurrentApplication();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.applicationSaveError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);

    try {
      // Salvează datele finale
      await _saveCurrentStep();
      
      // Trimite aplicația
      await _applicationService.submitApplication();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.applicationSubmitSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.applicationSubmitError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('prea mare')) {
      return AppLocalizations.of(context)!.fileTooLarge;
    } else if (errorString.contains('404') || errorString.contains('Not Found')) {
      return AppLocalizations.of(context)!.serviceUnavailable;
    } else if (errorString.contains('Network')) {
      return AppLocalizations.of(context)!.connectionError;
    } else {
      return AppLocalizations.of(context)!.unexpectedError;
    }
  }

  Widget _buildUploadButton(DriverDocumentType documentType) {
    if (_currentApplication == null) {
      return const CircularProgressIndicator();
    }

    final isUploaded = _applicationService.isDocumentUploaded(_currentApplication!, documentType);
    final isUploading = _uploadingStatus[documentType] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: InkWell(
          onTap: isUploading ? null : () => _showDocumentOptions(documentType),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isUploaded ? Icons.check_circle : Icons.upload_file,
                      color: isUploaded ? Colors.green : (documentType.isRequired ? Colors.orange : Colors.grey),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  documentType.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (documentType.isRequired)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.requiredBadge,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            documentType.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        isUploaded ? Icons.more_vert : Icons.add_a_photo,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isUploaded 
                      ? AppLocalizations.of(context)!.documentUploadedText 
                      : AppLocalizations.of(context)!.tapToUploadText,
                  style: TextStyle(
                    color: isUploaded ? Colors.green : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (isUploaded) ...[
                  const SizedBox(height: 8),
                  DriverDocumentStatusWidget(
                    document: _currentApplication!.documents[documentType]!,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildDocumentPreview(documentType),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(DriverDocumentType documentType) {
    final documentUrl = _applicationService.getDocumentUrl(_currentApplication!, documentType);
    if (documentUrl == null) return const SizedBox();

    if (documentUrl.endsWith('.pdf')) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 24, color: Colors.red),
              SizedBox(height: 4),
              Text('PDF', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
    }

    return Image.network(
      documentUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(Icons.error, color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildAccessCodeBanner() {
    final app = _currentApplication;
    if (app == null) return const SizedBox.shrink();
    if (!['activated', 'approved'].contains(app.status)) return const SizedBox.shrink();
    if (app.accessCode == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.teal, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.accountActivated,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cod acces: ${app.accessCode}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.teal,
                  ),
                ),
                if (app.accessCodeGeneratedAt != null)
                  Text(
                    AppLocalizations.of(context)!.accessCodeGeneratedAt(DateFormat('dd.MM.yyyy HH:mm').format(app.accessCodeGeneratedAt!)),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_currentApplication == null) return const SizedBox();
    
    final progress = _currentApplication!.completionPercentage;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.applicationProgress,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? AppLocalizations.of(context)!.applicationComplete
                : AppLocalizations.of(context)!.applicationIncomplete,
            style: TextStyle(
              fontSize: 12,
              color: progress >= 1.0 ? Colors.green : Colors.grey.shade600,
              fontWeight: progress >= 1.0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentApplication == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.bePartnerDriver),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bePartnerDriver),
        actions: [
          if (_currentApplication != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_currentApplication!.completionPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DriverApplicationData?>(
        stream: _applicationService.applicationStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _currentApplication = snapshot.data;
            if (_currentApplication != null) {
              _populateControllers(_currentApplication!);
            }
          }

          return Column(
            children: [
              _buildProgressIndicator(),
              _buildAccessCodeBanner(),
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () async {
                    if (_currentStep < 2) {
                      await _saveCurrentStep();
                      setState(() => _currentStep += 1);
                    } else {
                      await _submitApplication();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        if (details.stepIndex < 2)
                          ElevatedButton(
                            onPressed: _isLoading ? null : details.onStepContinue,
                            child: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(AppLocalizations.of(context)!.continueBtn),
                          )
                        else
                          ElevatedButton(
                            onPressed: _isLoading || (_currentApplication?.isComplete != true) 
                                ? null 
                                : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(AppLocalizations.of(context)!.submitApplication, style: const TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(width: 8),
                        if (details.stepIndex > 0)
                          TextButton(
                            onPressed: _isLoading ? null : details.onStepCancel,
                            child: Text(AppLocalizations.of(context)!.backBtn),
                          ),
                      ],
                    );
                  },
                  steps: [
                    // Step 1: Personal Information
                    Step(
                      title: Text(AppLocalizations.of(context)!.personalInfoStep),
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.fullNameLabel,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.ageLabel,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          _buildUploadButton(DriverDocumentType.profilePhoto),
                          _buildUploadButton(DriverDocumentType.idCard),
                          _buildUploadButton(DriverDocumentType.drivingLicenseFront),
                          _buildUploadButton(DriverDocumentType.drivingLicenseBack),
                        ],
                      ),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    ),
                    // Step 2: Vehicle Information
                    Step(
                      title: Text(AppLocalizations.of(context)!.vehicleInfoStep),
                      content: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _carBrandController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.carBrandLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _carModelController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.carModelLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _carColorController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.carColorLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _carYearController,
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.carYearLabel,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _licensePlateController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.licensePlateLabel,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildUploadButton(DriverDocumentType.carExterior),
                          _buildUploadButton(DriverDocumentType.carInsurance),
                        ],
                      ),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    ),
                    // Step 3: Final Documents
                    Step(
                      title: Text(AppLocalizations.of(context)!.finalDocumentsStep),
                      content: Column(
                        children: [
                          _buildUploadButton(DriverDocumentType.criminalRecord),
                          _buildUploadButton(DriverDocumentType.transportAttestation),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bankAccountController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.bankAccountLabel,
                              border: OutlineInputBorder(),
                              hintText: 'RO49 AAAA 1B31 0075 9384 0000',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.importantInfoTitle,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.applicationConfirmationText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          if (_currentApplication?.isComplete == false) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.applicationIncompleteWarning,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      isActive: _currentStep >= 2,
                      state: _currentStep >= 2 ? StepState.complete : StepState.indexed,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}