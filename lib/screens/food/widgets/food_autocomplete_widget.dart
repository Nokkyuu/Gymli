import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/food_data_controller.dart';
import '../../../utils/api/api_models.dart';

/// Widget for food autocomplete selection
class FoodAutocompleteWidget extends StatelessWidget {
  const FoodAutocompleteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodDataController>(
      builder: (context, controller, child) {
        return Autocomplete<ApiFood>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return controller.foods;
            }
            return controller.foods.where((ApiFood food) => food.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          displayStringForOption: (ApiFood food) => food.name,
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'Type to search foods...',
              ),
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<ApiFood> onSelected,
              Iterable<ApiFood> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ApiFood food = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(food),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${food.kcalPer100g.toInt()} kcal/100g',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (ApiFood selectedFood) {
            controller.setSelectedFood(selectedFood.name);
          },
        );
      },
    );
  }
}
