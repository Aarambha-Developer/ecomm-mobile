import 'package:flutter/material.dart';
import 'package:aarambha_app/features/products/presentation/screens/product_list_screen.dart';

class BrandProductsScreen extends StatelessWidget {
  final String slug;

  const BrandProductsScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ProductListScreen(initialBrandSlug: slug);
  }
}
