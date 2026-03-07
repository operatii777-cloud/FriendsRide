import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/models/driver_document_model.dart';
import 'package:friendsride_app/services/driver_application_service.dart';
import 'package:intl/intl.dart';

/// Admin screen that lists all pending driver applications and lets an admin
/// approve or reject each document individually.  Once all required documents
/// are approved the admin can activate the driver, which generates a 6-digit
/// access code.
class AdminDocumentReviewScreen extends StatelessWidget {
  const AdminDocumentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDocumentReview),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('driver_applications')
            .where('status', whereIn: ['submitted', 'under_review'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorPrefix(snapshot.error!)));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPendingApplications,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _ApplicantCard(userId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ApplicantCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _ApplicantCard({required this.userId, required this.data});

  bool _allRequiredApproved(Map<String, dynamic> data) {
    for (final docType in DriverDocumentType.values) {
      if (!docType.isRequired) continue;
      final status = data['${docType.name}_status'] as String?;
      if (status != 'approved') return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = data['fullName'] as String? ?? l10n.unknownApplicant;
    final appStatus = data['status'] as String? ?? 'submitted';
    final allApproved = _allRequiredApproved(data);
    final applicationData = DriverApplicationData.fromFirestore(data);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        l10n.statusLabel(appStatus),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(appStatus: appStatus),
              ],
            ),
            const Divider(height: 24),
            // ── Documents ───────────────────────────────────────────────────
            ...DriverDocumentType.values.map((docType) {
              final doc = applicationData.documents[docType];
              if (doc == null || !doc.isUploaded) {
                return _MissingDocRow(docType: docType);
              }
              return _DocumentReviewRow(
                userId: userId,
                document: doc,
              );
            }),
            const SizedBox(height: 12),
            // ── Activate button ─────────────────────────────────────────────
            if (allApproved && appStatus != 'activated')
              _ActivateDriverButton(userId: userId, applicantName: name),
            if (appStatus == 'activated')
              _AccessCodeDisplay(accessCode: data['accessCode'] as String?),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String appStatus;
  const _StatusChip({required this.appStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (appStatus) {
      'submitted' => (Colors.orange, l10n.statusSubmitted),
      'under_review' => (Colors.blue, l10n.statusUnderReview),
      'approved' => (Colors.green, l10n.statusApproved),
      'activated' => (Colors.teal, l10n.statusActivated),
      'rejected' => (Colors.red, l10n.statusRejected),
      _ => (Colors.grey, appStatus),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MissingDocRow extends StatelessWidget {
  final DriverDocumentType docType;
  const _MissingDocRow({required this.docType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, color: Colors.grey.shade400, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              docType.displayName,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Text(
            docType.isRequired ? l10n.missingRequired : l10n.missing,
            style: TextStyle(
              fontSize: 11,
              color: docType.isRequired ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DocumentReviewRow extends StatefulWidget {
  final String userId;
  final DriverDocument document;

  const _DocumentReviewRow({
    required this.userId,
    required this.document,
  });

  @override
  State<_DocumentReviewRow> createState() => _DocumentReviewRowState();
}

class _DocumentReviewRowState extends State<_DocumentReviewRow> {
  bool _loading = false;
  final _service = DriverApplicationService();

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await _service.updateDocumentStatus(
        widget.userId,
        widget.document.type,
        DriverDocumentStatus.approved,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.documentApproved(widget.document.type.displayName)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPrefix(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectDocumentTitle(widget.document.type.displayName)),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.rejectReason,
            hintText: l10n.rejectionHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.rejectTooltip, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _service.updateDocumentStatus(
        widget.userId,
        widget.document.type,
        DriverDocumentStatus.rejected,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n2.documentRejected(widget.document.type.displayName)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n2.errorPrefix(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewDocument() {
    final url = widget.document.url;
    if (url == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(widget.document.type.displayName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Flexible(
              child: InteractiveViewer(
                child: url.toLowerCase().endsWith('.pdf')
                    ? const SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Document PDF'),
                            ],
                          ),
                        ),
                      )
                    : Image.network(
                        url,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final statusColor = switch (doc.status) {
      DriverDocumentStatus.approved => Colors.green,
      DriverDocumentStatus.rejected => Colors.red,
      DriverDocumentStatus.pending => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              GestureDetector(
                onTap: _viewDocument,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: doc.url != null && !doc.url!.toLowerCase().endsWith('.pdf')
                        ? Image.network(
                            doc.url!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.type.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (doc.uploadedAt != null)
                      Text(
                        AppLocalizations.of(context)!.uploadedAt(DateFormat('dd.MM.yyyy HH:mm').format(doc.uploadedAt!)),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    if (doc.expiryDate != null)
                      Text(
                        AppLocalizations.of(context)!.docExpiresOn(DateFormat('dd.MM.yyyy').format(doc.expiryDate!)),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    Row(
                      children: [
                        Icon(
                          doc.status == DriverDocumentStatus.approved
                              ? Icons.check_circle
                              : doc.status == DriverDocumentStatus.rejected
                                  ? Icons.cancel
                                  : Icons.access_time,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doc.status.value,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else ...[
                if (doc.status != DriverDocumentStatus.approved)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    tooltip: AppLocalizations.of(context)!.approveTooltip,
                    onPressed: _approve,
                  ),
                if (doc.status != DriverDocumentStatus.rejected)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: AppLocalizations.of(context)!.rejectTooltip,
                    onPressed: _reject,
                  ),
              ],
            ],
          ),
          if (doc.status == DriverDocumentStatus.rejected &&
              doc.rejectionReason != null &&
              doc.rejectionReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 58, top: 4),
              child: Text(
                AppLocalizations.of(context)!.rejectionReasonLabel(doc.rejectionReason!),
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActivateDriverButton extends StatefulWidget {
  final String userId;
  final String applicantName;
  const _ActivateDriverButton({required this.userId, required this.applicantName});

  @override
  State<_ActivateDriverButton> createState() => _ActivateDriverButtonState();
}

class _ActivateDriverButtonState extends State<_ActivateDriverButton> {
  bool _loading = false;
  final _service = DriverApplicationService();

  Future<void> _activate() async {
    setState(() => _loading = true);
    try {
      final code = await _service.generateAndSendAccessCode(widget.userId);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.driverActivatedTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.driverActivatedContent(widget.applicantName)),
                const SizedBox(height: 16),
                Text(l10n.accessCodeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.sendCodeToDriver,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.activationError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _activate,
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.verified_user),
        label: Text(l10n.activateDriver),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AccessCodeDisplay extends StatelessWidget {
  final String? accessCode;
  const _AccessCodeDisplay({this.accessCode});

  @override
  Widget build(BuildContext context) {
    if (accessCode == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Text(l10n.accessCodeGenerated, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            accessCode!,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
