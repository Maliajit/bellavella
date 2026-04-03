import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/core/models/data_models.dart';
import 'package:bellavella/core/services/api_service.dart';
import 'package:bellavella/features/professional/services/professional_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late Professional _professional;
  bool _isRefreshing = false;

  // Locally picked files (if any during pending state)
  XFile? _pickedAadhaarFront;
  XFile? _pickedAadhaarBack;
  XFile? _pickedPan;
  XFile? _pickedCertificate;

  bool get isVerified => _professional.verification == 'Verified';

  @override
  void initState() {
    super.initState();
    _professional = widget.professional;
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final updatedPro = await ProfessionalApiService.getProfile();
      if (mounted) {
        setState(() {
          _professional = updatedPro;
        });
      }
    } catch (e) {
      debugPrint("KycDocumentsScreen: Refresh failed: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData(); // Ensures fresh data when dependencies change (like returning to screen)
  }

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
    
    if (url != null && url.toLowerCase().endsWith('.pdf')) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentViewModal(title: title, url: url, local: local),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isRefreshing && _professional.id.isEmpty) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final docs = _professional.documents ?? {};

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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              _buildDocTile("Aadhaar Card (Front)", "aadhaar_front", docs['aadhaar_front'], _pickedAadhaarFront, Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildDocTile("Aadhaar Card (Back)", "aadhaar_back", docs['aadhaar_back'], _pickedAadhaarBack, Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildDocTile("PAN Card Image", "pan_img", docs['pan_card'], _pickedPan, Icons.description_outlined),
              
              const SizedBox(height: 24),
              _buildSectionHeader("Address & Payout Verification"),
              const SizedBox(height: 12),
              _buildDocTile("Light Bill (Address Proof)", "light_bill", docs['light_bill'], null, Icons.bolt_outlined),
              const SizedBox(height: 12),
              _buildDocTile("Bank Proof (Passbook/Cheque)", "bank_proof", docs['bank_proof'], null, Icons.account_balance_outlined),

              const SizedBox(height: 24),
              _buildSectionHeader("Skill Verification"),
              const SizedBox(height: 12),
              _buildDocTile(
                "Professional Certificate",
                "certificate_img",
                _professional.certificateImg != null ? KycDocument(url: _professional.certificateImg, status: 'pending') : null,
                _pickedCertificate,
                Icons.school_outlined,
              ),
              const SizedBox(height: 32),
              if (!isVerified)
                _buildNoteCard(),
              const SizedBox(height: 100),
            ],
          ),
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
    final status = _professional.verification;
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

  Widget _buildDocTile(String title, String field, KycDocument? doc, XFile? local, IconData icon) {
    final url = doc?.url;
    final status = doc?.status ?? 'not_uploaded';
    final hasDoc = url != null || local != null;
    final isLoading = _uploading && _uploadingField == field;

    // Status mapping (Premium Hardened)
    Color statusColor;
    String statusText;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        statusColor = Colors.green;
        statusText = "Approved";
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = "Rejected";
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = hasDoc ? "Pending Review" : "Not Uploaded";
        break;
      default:
        statusColor = Colors.grey;
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
              child: hasDoc && url != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: doc!.isPdf 
                      ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(icon, color: Colors.blueGrey.shade600, size: 22),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)));
                          },
                        ),
                  )
                : Icon(icon, color: Colors.blueGrey.shade600, size: 22),
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
                  Row(
                    children: [
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
                      if (doc?.isPdf == true) ...[
                        const SizedBox(width: 8),
                        Text("(PDF)", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                      ],
                    ],
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
                  icon: Icon(doc?.isPdf == true ? Icons.open_in_new_rounded : Icons.visibility_outlined, color: Colors.blue),
                  onPressed: () => _viewDocument(context, title, url, local),
                ),
              if (!isVerified && status.toLowerCase() != 'approved' && status.toLowerCase() != 'verified')
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
