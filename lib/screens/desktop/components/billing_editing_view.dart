import 'package:flutter/material.dart';

class LineItemEditView extends StatefulWidget {
  final int index;
  final String description;
  final String subTitle;
  final int quantity;
  final double rate;
  final bool isLast;

  const LineItemEditView({
    super.key,
    required this.index,
    required this.description,
    required this.subTitle,
    required this.quantity,
    required this.rate,
    this.isLast = false,
  });

  @override
  State<LineItemEditView> createState() => _LineItemEditViewState();
}

class _LineItemEditViewState extends State<LineItemEditView> {
  late TextEditingController descriptionController;
  late TextEditingController subTitleController;
  late TextEditingController quantityController;
  late TextEditingController rateController;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(text: widget.description);
    subTitleController = TextEditingController(text: widget.subTitle);
    quantityController = TextEditingController(
      text: widget.quantity.toString(),
    );
    rateController = TextEditingController(
      text: widget.rate.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    subTitleController.dispose();
    quantityController.dispose();
    rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Line Item ${widget.index + 1}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: subTitleController,
            decoration: const InputDecoration(
              labelText: 'Sub Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: rateController,
            decoration: const InputDecoration(
              labelText: 'Rate',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle save logic here
                  final updatedDescription = descriptionController.text;
                  final updatedSubTitle = subTitleController.text;
                  final updatedQuantity =
                      int.tryParse(quantityController.text) ?? widget.quantity;
                  final updatedRate =
                      double.tryParse(rateController.text) ?? widget.rate;

                  // Pass the updated values back or save them
                  Navigator.pop(context, {
                    'description': updatedDescription,
                    'subTitle': updatedSubTitle,
                    'quantity': updatedQuantity,
                    'rate': updatedRate,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
