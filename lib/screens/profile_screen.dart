import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dailyGoalController = TextEditingController();
  final _weeklyGoalController = TextEditingController();

  String? _selectedGender; // 'male' | 'female' | 'other'

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dailyGoalController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    _formKey.currentState?.save();

    // Здесь вместо print ты подключишь свой репозиторий/Bloc/Provider.
    final profileData = {
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'age': int.tryParse(_ageController.text),
      'dailyGoal': int.tryParse(_dailyGoalController.text),
      'weeklyGoal': int.tryParse(_weeklyGoalController.text),
    };

    debugPrint('Profile saved: $profileData');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Личные данные',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Имя
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  if (value.trim().length < 2) {
                    return 'Имя слишком короткое';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Пол
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Мужской')),
                  DropdownMenuItem(value: 'female', child: Text('Женский')),
                  DropdownMenuItem(value: 'other', child: Text('Другое')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Пол',
                  prefixIcon: Icon(Icons.wc),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите пол';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Возраст
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите возраст';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Введите корректное число';
                  }
                  if (age < 5 || age > 120) {
                    return 'Введите возраст от 5 до 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Цели по шагам',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Цель на день
              TextFormField(
                controller: _dailyGoalController,
                decoration: const InputDecoration(
                  labelText: 'Цель на день (шаги)',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите дневную цель по шагам';
                  }
                  final steps = int.tryParse(value);
                  if (steps == null || steps <= 0) {
                    return 'Введите положительное число шагов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Цель на неделю
              TextFormField(
                controller: _weeklyGoalController,
                decoration: const InputDecoration(
                  labelText: 'Цель на неделю (шаги)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите недельную цель по шагам';
                  }
                  final steps = int.tryParse(value);
                  if (steps == null || steps <= 0) {
                    return 'Введите положительное число шагов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onSave,
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
