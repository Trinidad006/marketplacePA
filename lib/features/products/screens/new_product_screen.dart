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

/// Pantalla simple para crear nuevo producto
class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String? _selectedCategory;
  List<File> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('✅ NewProductScreen initState');
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
    if (_images.length >= AppConstants.maxProductImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 imágenes'),
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
      final remainingSlots = AppConstants.maxProductImages - _images.length;
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _images.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar autenticación y rol de vendedor
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes estar autenticado para crear productos'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!authProvider.isSeller) {
      debugPrint('❌ Usuario no es vendedor. Rol actual: ${authProvider.userProfile?.role.value ?? "desconocido"}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo los vendedores pueden crear productos. Tu rol actual es: ${authProvider.userProfile?.role.value ?? "desconocido"}'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una imagen'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validar y parsear precio
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precio inválido'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validar y parsear stock
    final stockText = _stockController.text.trim();
    final stock = int.tryParse(stockText);
    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock inválido'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🛒 Intentando crear producto...');
      debugPrint('📋 Usuario ID: ${authProvider.userProfile?.id}');
      debugPrint('📋 Rol: ${authProvider.userProfile?.role.value}');
      debugPrint('📋 Es vendedor: ${authProvider.isSeller}');

      final provider = context.read<ProductsProvider>();
      final result = await provider.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        category: _selectedCategory!,
        stock: stock,
        images: _images,
        isFeatured: false,
      );

      if (!mounted) return;

      if (result == null) {
        // El provider retornó null, hay un error
        final errorMessage = provider.errorMessage ?? 'Error al crear el producto';
        debugPrint('❌ Error al crear producto: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        // Producto creado exitosamente
        debugPrint('✅ Producto creado exitosamente: ${result.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Excepción al crear producto: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 NewProductScreen build - INICIANDO');
    
    try {
      // Verificar que el contexto tenga los providers necesarios
      AuthProvider? authProvider;
      try {
        authProvider = context.watch<AuthProvider>();
        debugPrint('📝 AuthProvider status: ${authProvider.status}');
        debugPrint('📝 Usuario autenticado: ${authProvider.isAuthenticated}');
        debugPrint('📝 Es vendedor: ${authProvider.isSeller}');
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener AuthProvider: $e');
        // Continuar sin el provider, el widget debería funcionar de todas formas
      }
      
      return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Producto'),
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
            const Text(
              'Imágenes (máximo 3)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(entry.value),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: const EdgeInsets.all(4),
                              ),
                              onPressed: () => _removeImage(entry.key),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_images.length < AppConstants.maxProductImages)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
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
                hintText: 'Ej: Jarrón de cerámica',
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
                hintText: 'Describe tu producto (mínimo 50 caracteres)',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
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

            // Precio
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                hintText: '0.00',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el precio';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Precio debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el stock';
                }
                final stock = int.tryParse(value);
                if (stock == null || stock < 0) {
                  return 'Stock no puede ser negativo';
                }
                return null;
              },
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
            const SizedBox(height: 32),

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
                  : const Text('Publicar Producto'),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      debugPrint('❌ Error en build de NewProductScreen: $e');
      debugPrint('📚 Stack trace: $stackTrace');
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
              const Text('Error al cargar la pantalla'),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

