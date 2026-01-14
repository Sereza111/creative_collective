import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/teams_provider.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  const AddTeamScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return; // Prevent multiple submissions
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await ref.read(teamsProvider.notifier).createTeam({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Команда создана'),
              backgroundColor: AppTheme.shadowGray,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.bloodRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('СОЗДАТЬ КОМАНДУ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTheme.fadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'НАЗВАНИЕ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTheme.gothicTextField(
                      controller: _nameController,
                      hintText: 'Введите название команды',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ОПИСАНИЕ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.mistGray,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTheme.gothicTextField(
                      controller: _descriptionController,
                      hintText: 'Опишите команду',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1100),
                child: AppTheme.gothicButton(
                  text: _isSubmitting ? 'Создание...' : 'Создать команду',
                  onPressed: () => _submitForm(),
                  isPrimary: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              AppTheme.fadeInAnimation(
                duration: const Duration(milliseconds: 1200),
                child: AppTheme.gothicButton(
                  text: 'Отмена',
                  onPressed: () => Navigator.pop(context),
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

