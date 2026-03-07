import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificare Documente Șoferi'),
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
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Nu există aplicații în așteptare.',
                    style: TextStyle(fontSize: 16),
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
    final name = data['fullName'] as String? ?? 'Aplicant necunoscut';
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
                        'Status: $appStatus',
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
    final (color, label) = switch (appStatus) {
      'submitted' => (Colors.orange, 'Trimis'),
      'under_review' => (Colors.blue, 'În revizuire'),
      'approved' => (Colors.green, 'Aprobat'),
      'activated' => (Colors.teal, 'Activat'),
      'rejected' => (Colors.red, 'Respins'),
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
            docType.isRequired ? 'Lipsă (obligatoriu)' : 'Lipsă',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${widget.document.type.displayName} aprobat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Respinge: ${widget.document.type.displayName}'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motiv respingere',
            hintText: 'ex. Imagine neclară, document expirat',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Respinge', style: TextStyle(color: Colors.white)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${widget.document.type.displayName} respins'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
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
                        'Încărcat: ${DateFormat('dd.MM.yyyy HH:mm').format(doc.uploadedAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    if (doc.expiryDate != null)
                      Text(
                        'Expiră: ${DateFormat('dd.MM.yyyy').format(doc.expiryDate!)}',
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
                    tooltip: 'Aprobă',
                    onPressed: _approve,
                  ),
                if (doc.status != DriverDocumentStatus.rejected)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Respinge',
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
                'Motiv: ${doc.rejectionReason}',
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
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Șofer Activat ✅'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.applicantName} a fost activat cu succes.'),
                const SizedBox(height: 16),
                const Text('Cod de acces:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text(
                  'Transmiteți acest cod șoferului.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Închide'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la activare: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _activate,
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.verified_user),
        label: const Text('Activează Șofer'),
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
          const Text('Cod de acces generat:', style: TextStyle(fontWeight: FontWeight.bold)),
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
