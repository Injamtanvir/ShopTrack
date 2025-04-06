// // import 'package:flutter/material.dart';
// // import '../models/product.dart';
// // import '../services/api_service.dart';
// // import '../widgets/custom_button.dart';
// //
// // class ProductListScreen extends StatefulWidget {
// //   static const routeName = '/product-list';
// //
// //   const ProductListScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   State<ProductListScreen> createState() => _ProductListScreenState();
// // }
// //
// // class _ProductListScreenState extends State<ProductListScreen> {
// //   final ApiService _apiService = ApiService();
// //   List<Product> _products = [];
// //   bool _isLoading = true;
// //   String? _errorMessage;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadProducts();
// //   }
// //
// //   Future<void> _loadProducts() async {
// //     setState(() {
// //       _isLoading = true;
// //       _errorMessage = null;
// //     });
// //
// //     try {
// //       final productsJson = await _apiService.getProducts();
// //       setState(() {
// //         _products = productsJson.map<Product>((json) => Product.fromJson(json)).toList();
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _errorMessage = e.toString();
// //         _isLoading = false;
// //       });
// //     }
// //   }
// //
// //   Future<void> _updatePrice(Product product) async {
// //     final TextEditingController controller = TextEditingController(
// //       text: product.sellingPrice.toString(),
// //     );
// //
// //     return showDialog<void>(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Update Price for ${product.name}'),
// //           content: TextField(
// //             controller: controller,
// //             keyboardType: const TextInputType.numberWithOptions(decimal: true),
// //             decoration: const InputDecoration(
// //               labelText: 'New Selling Price',
// //               border: OutlineInputBorder(),
// //             ),
// //           ),
// //           actions: <Widget>[
// //             TextButton(
// //               child: const Text('Cancel'),
// //               onPressed: () {
// //                 Navigator.of(context).pop();
// //               },
// //             ),
// //             TextButton(
// //               child: const Text('Update'),
// //               onPressed: () async {
// //                 if (double.tryParse(controller.text) != null) {
// //                   Navigator.of(context).pop();
// //
// //                   try {
// //                     await _apiService.updateProductPrice(
// //                       productId: product.id,
// //                       sellingPrice: double.parse(controller.text),
// //                     );
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       const SnackBar(content: Text('Price updated successfully')),
// //                     );
// //                     _loadProducts(); // Reload the list
// //                   } catch (e) {
// //                     ScaffoldMessenger.of(context).showSnackBar(
// //                       SnackBar(content: Text('Error: ${e.toString()}')),
// //                     );
// //                   }
// //                 }
// //               },
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Product List'),
// //         backgroundColor: Colors.indigo,
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: _loadProducts,
// //             tooltip: 'Refresh',
// //           ),
// //         ],
// //       ),
// //       body: _isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : _errorMessage != null
// //           ? Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               Text(
// //                 'Error: $_errorMessage',
// //                 style: const TextStyle(color: Colors.red),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 16),
// //               CustomButton(
// //                 text: 'Retry',
// //                 onPressed: _loadProducts,
// //               ),
// //             ],
// //           ),
// //         ),
// //       )
// //           : _products.isEmpty
// //           ? const Center(
// //         child: Text('No products found. Add some products!'),
// //       )
// //           : ListView.builder(
// //         itemCount: _products.length,
// //         itemBuilder: (context, index) {
// //           final product = _products[index];
// //           return Card(
// //             margin: const EdgeInsets.symmetric(
// //               horizontal: 16,
// //               vertical: 8,
// //             ),
// //             child: ListTile(
// //               title: Text(
// //                 product.name,
// //                 style: const TextStyle(
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               subtitle: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text('Quantity: ${product.quantity}'),
// //                   Text(
// //                     'Selling Price: \$${product.sellingPrice.toStringAsFixed(2)}',
// //                     style: const TextStyle(
// //                       color: Colors.green,
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   ),
// //                   Text(
// //                     'Buying Price: \$${product.buyingPrice.toStringAsFixed(2)}',
// //                   ),
// //                 ],
// //               ),
// //               trailing: IconButton(
// //                 icon: const Icon(Icons.edit),
// //                 onPressed: () => _updatePrice(product),
// //                 tooltip: 'Update Price',
// //               ),
// //               isThreeLine: true,
// //             ),
// //           );
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () async {
// //           final result = await Navigator.pushNamed(context, '/add-product');
// //           if (result == true) {
// //             _loadProducts();
// //           }
// //         },
// //         backgroundColor: Colors.indigo,
// //         child: const Icon(Icons.add),
// //         tooltip: 'Add Product',
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
//
//
// import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart' show TextInputType;
// import '../models/product.dart';
// import '../services/api_service.dart';
// import '../widgets/custom_button.dart';
//
// class ProductListScreen extends StatefulWidget {
//   static const routeName = '/product-list';
//
//   const ProductListScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ProductListScreen> createState() => _ProductListScreenState();
// }
//
// class _ProductListScreenState extends State<ProductListScreen> {
//   final ApiService _apiService = ApiService();
//   List<Product> _products = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }
//
//   Future<void> _loadProducts() async {
//     if (!mounted) return;
//
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final productsJson = await _apiService.getProducts();
//       if (!mounted) return;
//
//       setState(() {
//         _products = productsJson.map<Product>((json) => Product.fromJson(json)).toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _updatePrice(Product product) async {
//     final TextEditingController controller = TextEditingController(
//       text: product.sellingPrice.toString(),
//     );
//
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: Text('Update Price for ${product.name}'),
//           content: TextField(
//             controller: controller,
//             // keyboardType: TextInputType.numberWithOptions(decimal: true),
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             decoration: const InputDecoration(
//               labelText: 'New Selling Price',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Update'),
//               onPressed: () async {
//                 if (double.tryParse(controller.text) != null) {
//                   Navigator.of(dialogContext).pop();
//
//                   try {
//                     await _apiService.updateProductPrice(
//                       productId: product.id,
//                       sellingPrice: double.parse(controller.text),
//                     );
//
//                     if (!mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Price updated successfully')),
//                     );
//                     _loadProducts(); // Reload the list
//                   } catch (e) {
//                     if (!mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error: ${e.toString()}')),
//                     );
//                   }
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Product List'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadProducts,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Error: $_errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               CustomButton(
//                 text: 'Retry',
//                 onPressed: _loadProducts,
//               ),
//             ],
//           ),
//         ),
//       )
//           : _products.isEmpty
//           ? const Center(
//         child: Text('No products found. Add some products!'),
//       )
//           : ListView.builder(
//         itemCount: _products.length,
//         itemBuilder: (context, index) {
//           final product = _products[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             child: ListTile(
//               title: Text(
//                 product.name,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Quantity: ${product.quantity}'),
//                   Text(
//                     'Selling Price: \$${product.sellingPrice.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       color: Colors.green,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   Text(
//                     'Buying Price: \$${product.buyingPrice.toStringAsFixed(2)}',
//                   ),
//                 ],
//               ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed: () => _updatePrice(product),
//                 tooltip: 'Update Price',
//               ),
//               isThreeLine: true,
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.indigo,
//         onPressed: () async {
//           final result = await Navigator.pushNamed(context, '/add-product');
//           if (result == true) {
//             _loadProducts();
//           }
//         },
//         tooltip: 'Add Product',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }





import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show TextInputType;
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class ProductListScreen extends StatefulWidget {
  static const routeName = '/product-list';
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productsJson = await _apiService.getProducts();
      if (!mounted) return;

      setState(() {
        _products = productsJson.map<Product>((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrice(Product product) async {
    final TextEditingController controller = TextEditingController(
      text: product.sellingPrice.toString(),
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Price for ${product.name}'),
          content: TextField(
            controller: controller,
            // keyboardType: TextInputType.numberWithOptions(decimal: true),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'New Selling Price',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                if (double.tryParse(controller.text) != null) {
                  Navigator.of(dialogContext).pop();

                  try {
                    await _apiService.updateProductPrice(
                      productId: product.id,
                      sellingPrice: double.parse(controller.text),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Price updated successfully')),
                    );

                    _loadProducts(); // Reload the list
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // New method to delete a product
  Future<void> _deleteProduct(Product product) async {
    // Show confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text(
            'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    // Proceed with deletion
    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.deleteProduct(product.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );

      _loadProducts(); // Reload the list
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: _loadProducts,
              ),
            ],
          ),
        ),
      )
          : _products.isEmpty
          ? const Center(
        child: Text('No products found. Add some products!'),
      )
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity: ${product.quantity}'),
                  Text(
                    'Selling Price: \$${product.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Buying Price: \$${product.buyingPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _updatePrice(product),
                    tooltip: 'Update Price',
                  ),
                  // Delete button - new
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProduct(product),
                    tooltip: 'Delete Product',
                    color: Colors.red,
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-product');
          if (result == true) {
            _loadProducts();
          }
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}