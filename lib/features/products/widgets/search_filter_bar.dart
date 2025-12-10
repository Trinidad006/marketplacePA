import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Barra de búsqueda con filtros desplegables
class SearchFilterBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final ProductFilters currentFilters;
  final Function(ProductFilters) onFiltersChanged;

  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  bool _showFilters = false;
  String? _selectedCategory;
  String _selectedSort = 'recent';
  RangeValues _priceRange = const RangeValues(0, 10000);
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentFilters.category;
    _selectedSort = widget.currentFilters.sortBy;
    _onlyAvailable = widget.currentFilters.onlyAvailable;
    if (widget.currentFilters.minPrice != null ||
        widget.currentFilters.maxPrice != null) {
      _priceRange = RangeValues(
        widget.currentFilters.minPrice ?? 0,
        widget.currentFilters.maxPrice ?? 10000,
      );
    }
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      widget.currentFilters.copyWith(
        category: _selectedCategory,
        sortBy: _selectedSort,
        minPrice: _priceRange.start > 0 ? _priceRange.start : null,
        maxPrice: _priceRange.end < 10000 ? _priceRange.end : null,
        onlyAvailable: _onlyAvailable,
      ),
    );
    setState(() {
      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSort = 'recent';
      _priceRange = const RangeValues(0, 10000);
      _onlyAvailable = false;
    });
    widget.onFiltersChanged(const ProductFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.controller,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondaryLight,
                    ),
                    suffixIcon: widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.controller.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botón de filtros
            Container(
              decoration: BoxDecoration(
                color: _showFilters || widget.currentFilters.hasFilters
                    ? AppTheme.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune,
                  color: _showFilters || widget.currentFilters.hasFilters
                      ? Colors.white
                      : AppTheme.textSecondaryLight,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
            ),
          ],
        ),

        // Panel de filtros
        if (_showFilters) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoría
                Text(
                  'Categoría',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    ...AppConstants.productCategories.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Rango de precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      '\$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Solo disponibles
                SwitchListTile(
                  title: const Text('Solo disponibles'),
                  value: _onlyAvailable,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _onlyAvailable = value;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Ordenamiento
                Text(
                  'Ordenar por',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.sortOptions.entries.map((entry) {
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: _selectedSort == entry.key,
                      onSelected: (_) {
                        setState(() {
                          _selectedSort = entry.key;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

