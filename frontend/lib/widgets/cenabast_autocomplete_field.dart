import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CenabastAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const CenabastAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Nombre del remedio (Catálogo CENABAST)',
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<MedicamentoModel>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.length < 2) {
          return const Iterable<MedicamentoModel>.empty();
        }
        final results = await ApiService.getMedications(query: query);
        return results;
      },
      displayStringForOption: (MedicamentoModel option) => option.nombre,
      onSelected: (MedicamentoModel selection) {
        controller.text = selection.nombre;
      },
      fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: const Icon(Icons.medication),
            suffixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF0284C7)),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width - 72,
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final MedicamentoModel option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.medication_liquid, size: 18, color: Color(0xFF0284C7)),
                    title: Text(
                      option.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
