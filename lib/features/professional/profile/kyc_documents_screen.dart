import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/api_service.dart';

class KycDocumentsScreen extends StatefulWidget {
  final Professional professional;
  const KycDocumentsScreen({super.key, required this.professional});

  @override
  State<KycDocumentsScreen> createState() => _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends State<KycDocumentsScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _uploadingField;

  // Locally picked files (if any during pending state)
  XFile? _pickedAadhaarFront;
  XFile? _pickedAadhaarBack;
  XFile? _pickedPan;
  XFile? _pickedCertificate;

  bool get isVerified => widget.professional.verification == 'Verified';

  Future<void> _pickAndUpload(String field) async {
    if (isVerified) return; // Guard clause

    final picked = await _picker.pickImage(
      source: field == 'selfie' ? ImageSource.camera : ImageSource.gallery, 
      imageQuality: 85,
      preferredCameraDevice: field == 'selfie' ? CameraDevice.front : CameraDevice.rear,
    );
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _uploadingField = field;
      if (field == 'aadhaar_front') _pickedAadhaarFront = picked;
      if (field == 'aadhaar_back') _pickedAadhaarBack = picked;
      if (field == 'pan_img') _pickedPan = picked;
      if (field == 'certificate_img') _pickedCertificate = picked;
    });

    try {
      await ApiService.multipart('professional/upload-documents', {}, {field: picked});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          if (field == 'aadhaar_front') _pickedAadhaarFront = null;
          if (field == 'aadhaar_back') _pickedAadhaarBack = null;
          if (field == 'pan_img') _pickedPan = null;
          if (field == 'certificate_img') _pickedCertificate = null;
        });
      }
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadingField = null; });
    }
  }

  void _viewDocument(BuildContext context, String title, String? url, XFile? local) {
    if (url == null && local == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document uploaded to view')),
      );
      return;
    }
    
    debugPrint("KycDocumentsScreen: Viewing document '$title' with URL: $url");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentViewModal(title: title, url: url, local: local),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.professional.documents ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification Center',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            Text(
              "Document Status",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Track your verification progress below",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader("Identity Documents"),
            const SizedBox(height: 12),
            _buildDocTile(
              "Aadhaar Card (Front)",
              "aadhaar_front",
              docs['aadhaar_front']?['url']?.toString(),
              _pickedAadhaarFront,
              docs['aadhaar_front']?['status']?.toString() ?? 'pending',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              "Aadhaar Card (Back)",
              "aadhaar_back",
              docs['aadhaar_back']?['url']?.toString(),
              _pickedAadhaarBack,
              docs['aadhaar_back']?['status']?.toString() ?? 'pending',
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              "PAN Card Image",
              "pan_img",
              docs['pan_card']?['url']?.toString(),
              _pickedPan,
              docs['pan_card']?['status']?.toString() ?? 'pending',
              Icons.description_outlined,
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader("Address & Payout Verification"),
            const SizedBox(height: 12),
            _buildDocTile(
              "Light Bill (Address Proof)",
              "light_bill",
              docs['light_bill']?['url']?.toString(),
              null, // Not locally pickable in this screen yet but can be added
              docs['light_bill']?['status']?.toString() ?? 'pending',
              Icons.bolt_outlined,
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              "Bank Proof (Passbook/Cheque)",
              "bank_proof",
              docs['bank_proof']?['url']?.toString(),
              null,
              docs['bank_proof']?['status']?.toString() ?? 'pending',
              Icons.account_balance_outlined,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Skill Verification"),
            const SizedBox(height: 12),
            _buildDocTile(
              "Professional Certificate",
              "certificate_img",
              widget.professional.certificateImg, // Fallback to old field
              _pickedCertificate,
              'pending', // Status not yet implemented for certificates in API specifically but can be added
              Icons.school_outlined,
            ),
            const SizedBox(height: 32),
            if (!isVerified)
              _buildNoteCard(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 15, 
          fontWeight: FontWeight.w600, 
          color: Colors.blueGrey.shade700
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = widget.professional.verification;
    final isVerified = status == 'Verified';
    final color = isVerified ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              isVerified ? Icons.verified_user_rounded : (status == 'Rejected' ? Icons.error_rounded : Icons.history_edu_rounded),
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? "Profile Verified" : (status == 'Rejected' ? "Verification Rejected" : "Review in Progress"),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isVerified 
                      ? "All documents are approved." 
                      : (status == 'Rejected' ? "Please fix rejected documents." : "We are checking your documents."),
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isVerified)
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildDocTile(String title, String field, String? url, XFile? local, String status, IconData icon) {
    final hasDoc = url != null || local != null;
    final isLoading = _uploading && _uploadingField == field;

    // Status mapping
    Color statusColor;
    String statusText;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = "Approved";
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = "Rejected";
        break;
      default:
        statusColor = Colors.orange;
        statusText = hasDoc ? "Pending Review" : "Not Uploaded";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.toLowerCase() == 'rejected' ? Colors.red.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.blueGrey.shade600, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              )
            else ...[
              if (hasDoc)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                  onPressed: () => _viewDocument(context, title, url, local),
                ),
              if (!isVerified && status.toLowerCase() != 'approved')
                IconButton(
                  icon: Icon(hasDoc ? Icons.refresh_rounded : Icons.file_upload_outlined, color: AppTheme.primaryColor),
                  onPressed: () => _pickAndUpload(field),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Important: Once a document is 'Approved', you won't be able to replace it. Rejection reasons will be shared by admin.",
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.blue.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentViewModal extends StatelessWidget {
  final String title;
  final String? url;
  final XFile? local;

  const _DocumentViewModal({required this.title, this.url, this.local});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (local != null) {
      return kIsWeb ? Image.network(local!.path, fit: BoxFit.contain) : Image.file(File(local!.path), fit: BoxFit.contain);
    }
    if (url != null) {
      return Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        },
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    }
    return const SizedBox.shrink();
  }
}
