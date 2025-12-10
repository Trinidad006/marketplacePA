import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla de formulario para crear/editar producto
class ProductFormScreen extends StatefulWidget {
  final String? productId;

  const ProductFormScreen({
    super.key,
    this.productId,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String? _selectedCategory;
  bool _isFeatured = false;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  double _uploadProgress = 0;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    debugPrint('📝 ProductFormScreen initState - isEditing: $_isEditing');
    if (_isEditing) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final provider = context.read<ProductsProvider>();
    final product = provider.sellerProducts.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => throw Exception('Producto no encontrado'),
    );

    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _selectedCategory = product.category;
    _isFeatured = product.isFeatured;
    _existingImageUrls = List.from(product.images);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImages = _newImages.length + _existingImageUrls.length;
    if (totalImages >= AppConstants.maxProductImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 imágenes por producto'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      final remainingSlots = AppConstants.maxProductImages - totalImages;
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _newImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una imagen'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      final provider = context.read<ProductsProvider>();

      if (_isEditing) {
        // TODO: Implementar actualización con nuevas imágenes
        await provider.updateProduct(
          productId: widget.productId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory!,
          stock: int.parse(_stockController.text),
          images: _existingImageUrls,
          isFeatured: _isFeatured,
        );
      } else {
        await provider.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory!,
          stock: int.parse(_stockController.text),
          images: _newImages,
          isFeatured: _isFeatured,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Producto actualizado' : 'Producto creado',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 ProductFormScreen build iniciado');
    final authProvider = context.watch<AuthProvider>();
    
    debugPrint('📝 Auth status: ${authProvider.status}');
    debugPrint('📝 isSeller: ${authProvider.isSeller}');
    debugPrint('📝 userProfile: ${authProvider.userProfile?.role.value}');
    
    // Verificar que el usuario esté autenticado
    if (authProvider.status == AuthStatus.loading) {
      debugPrint('📝 Mostrando loading...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Verificar que el usuario sea vendedor
    if (!authProvider.isSeller) {
      debugPrint('📝 Usuario no es vendedor, mostrando error');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Solo los vendedores pueden publicar productos'),
              const SizedBox(height: 8),
              Text('Rol actual: ${authProvider.userProfile?.role.value ?? "desconocido"}'),
            ],
          ),
        ),
      );
    }
    
    debugPrint('📝 Usuario es vendedor, verificando canFeature...');
    bool canFeature;
    try {
      canFeature = _checkCanFeature();
      debugPrint('📝 canFeature: $canFeature');
    } catch (e) {
      debugPrint('❌ Error en _checkCanFeature: $e');
      // Si hay error, permitir featured por defecto
      canFeature = true;
    }
    
    debugPrint('📝 Construyendo formulario...');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Imágenes
            Text(
              'Imágenes (máximo 3)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Imágenes existentes
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    return _ImageTile(
                      imageUrl: entry.value,
                      onRemove: () => _removeExistingImage(entry.key),
                    );
                  }),
                  // Nuevas imágenes
                  ..._newImages.asMap().entries.map((entry) {
                    return _ImageTile(
                      imageFile: entry.value,
                      onRemove: () => _removeNewImage(entry.key),
                    );
                  }),
                  // Botón agregar
                  if (_newImages.length + _existingImageUrls.length <
                      AppConstants.maxProductImages)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Agregar',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                hintText: 'Ej: Jarrón de cerámica pintado a mano',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Describe tu producto en detalle...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una descripción';
                }
                if (value.length < AppConstants.minDescriptionLength) {
                  return 'Mínimo ${AppConstants.minDescriptionLength} caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Precio y Stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Precio inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      final stock = int.tryParse(value);
                      if (stock == null || stock < 0) {
                        return 'Stock inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
              ),
              items: AppConstants.productCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una categoría';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Destacado
            SwitchListTile(
              title: const Text('Producto destacado'),
              subtitle: Text(
                canFeature
                    ? 'Aparecerá con mayor visibilidad'
                    : 'Ya tienes ${AppConstants.maxFeaturedProducts} productos destacados',
                style: TextStyle(
                  color: canFeature
                      ? AppTheme.textSecondaryLight
                      : AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
              value: _isFeatured,
              activeColor: AppTheme.primaryColor,
              onChanged: canFeature || _isFeatured
                  ? (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 32),

            // Progreso de subida
            if (_isLoading && _uploadProgress > 0) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppTheme.accentColor.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Subiendo imágenes... ${(_uploadProgress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Guardar cambios' : 'Publicar producto'),
            ),
          ],
        ),
      ),
    );
  }

  bool _checkCanFeature() {
    try {
      final provider = context.read<ProductsProvider>();
      // Si no hay productos cargados, permitir featured (se cargarán después)
      if (provider.sellerProducts.isEmpty) {
        return true;
      }
      final featuredCount = provider.sellerProducts
          .where((p) => p.isFeatured && p.id != widget.productId)
          .length;
      return featuredCount < AppConstants.maxFeaturedProducts;
    } catch (e) {
      // Si hay error, permitir featured por defecto
      return true;
    }
  }
}

class _ImageTile extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback onRemove;

  const _ImageTile({
    this.imageUrl,
    this.imageFile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageFile != null
                ? Image.file(
                    imageFile!,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl!,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

