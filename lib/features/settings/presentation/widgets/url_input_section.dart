import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/settings_cubit.dart';

class UrlInputSection extends StatelessWidget {
  final TextEditingController urlController;
  final GlobalKey<FormState> formKey;

  const UrlInputSection({
    super.key,
    required this.urlController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Web URL',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Enter URL',
                  hintText: 'https://example.com',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || (!uri.scheme.startsWith('http'))) {
                    return 'Please enter a valid URL (http:// or https://)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context.read<SettingsCubit>().saveUrl(
                            urlController.text.trim(),
                          );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save URL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

