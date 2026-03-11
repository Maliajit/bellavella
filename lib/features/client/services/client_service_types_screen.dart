import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bellavella/core/theme/app_theme.dart';
import 'package:bellavella/features/client/services/controllers/service_provider.dart';
import 'package:bellavella/features/client/services/models/service_models.dart';
import 'package:bellavella/core/routes/app_routes.dart';
import 'package:go_router/go_router.dart';

class ClientServiceTypesScreen extends StatefulWidget {
  final String category; // This is the slug
  const ClientServiceTypesScreen({super.key, required this.category});

  @override
  State<ClientServiceTypesScreen> createState() => _ClientServiceTypesScreenState();
}

class _ClientServiceTypesScreenState extends State<ClientServiceTypesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServiceGroups(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Consumer<ServiceProvider>(
          builder: (context, sp, _) {
            String title = widget.category.replaceAll('-', ' ').toUpperCase();
            return Text(
              title,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, sp, _) {
          if (sp.isLoadingGroups) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sp.error != null) {
            return Center(child: Text('Error: ${sp.error}'));
          }

          final groups = sp.serviceGroups;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Service Type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the perfect experience for your needs',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  if (groups.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text('No service types found for this category.'),
                      ),
                    )
                  else
                    ...groups.map((group) => Column(
                      children: [
                        _buildCategoryCard(
                          context,
                          id: group.id,
                          title: group.name,
                          tag: group.tagLabel ?? 'PROFESSIONAL',
                          imageUrl: group.image ?? 'https://images.unsplash.com/photo-1560750588-73207b1ef5b8?q=80&w=400',
                          description: group.description ?? 'Standard professional services.',
                          slug: group.slug,
                        ),
                        const SizedBox(height: 16),
                      ],
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required int id,
    required String title,
    required String tag,
    required String imageUrl,
    required String description,
    required String slug,
  }) {
    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.clientServiceHierarchyName,
        pathParameters: {'nodeKey': slug},
        extra: {
          'seedNode': ServiceHierarchyNode(
            id: id.toString(),
            name: title,
            slug: slug,
            level: 'service_group',
            nextLevel: 'service_type',
            hasChildren: true,
            children: const [],
            image: imageUrl,
            description: description,
            tagLabel: tag,
          ).toRouteData(),
          'breadcrumbs': [
            ServiceHierarchyNode(
              id: '',
              name: widget.category.replaceAll('-', ' '),
              slug: widget.category,
              level: 'category',
              nextLevel: 'service_group',
              hasChildren: true,
              children: const [],
            ).toRouteData(),
          ],
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
