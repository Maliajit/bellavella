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
          'Verification',
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
              "Documents",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader("Identity Documents (Aadhaar & PAN)"),
            const SizedBox(height: 12),
            _buildDocTile(
              "Aadhaar Card (Front)",
              "aadhaar_front",
              widget.professional.aadhaarFront,
              _pickedAadhaarFront,
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              "Aadhaar Card (Back)",
              "aadhaar_back",
              widget.professional.aadhaarBack,
              _pickedAadhaarBack,
              Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildDocTile(
              "PAN Card Image",
              "pan_img",
              widget.professional.panImg,
              _pickedPan, 
              Icons.description_outlined,
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Skill Verification"),
            const SizedBox(height: 12),
            _buildDocTile(
              "Professional Certificate",
              "certificate_img",
              widget.professional.certificateImg,
              _pickedCertificate,
              Icons.school_outlined,
            ),
            const SizedBox(height: 32),
            if (!isVerified)
              _buildNoteCard(),
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
    final isPending = status != 'Verified' && status != 'Rejected';
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
                  isVerified ? "Verified Professional" : (status == 'Rejected' ? "Verification Rejected" : "Verification Pending"),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isVerified 
                      ? "Your documents are locked." 
                      : (status == 'Rejected' ? "Please re-upload correct documents." : "Review takes 24-48 hours."),
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

  Widget _buildDocTile(String title, String field, String? url, XFile? local, IconData icon) {
    final hasDoc = url != null || local != null;
    final isLoading = _uploading && _uploadingField == field;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isVerified) {
              _viewDocument(context, title, url, local);
            } else {
              _pickAndUpload(field);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.blueGrey.shade600, size: 20),
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
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else if (isVerified)
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasDoc ? "Replace" : "Upload",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
              "Important: Please ensure the images are clear and all details are readable. Original documents are preferred.",
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
      height: MediaQuery.of(context).size.height * 0.7,
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        },
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    }
    return const SizedBox.shrink();
  }
}
