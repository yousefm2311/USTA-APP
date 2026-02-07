#!/usr/bin/env bash

# تأكد إنك واقف في جذر مشروع Flutter
# نفس المكان اللي فيه pubspec.yaml

# ملفات أساسية
mkdir -p lib
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';

void main() {
  runApp(const UstaApp());
}

class UstaApp extends StatelessWidget {
  const UstaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Usta App Starter')),
      ),
    );
  }
}
EOF

# core
mkdir -p lib/core/theme
mkdir -p lib/core/utils
mkdir -p lib/core/constants
mkdir -p lib/core/bindings
mkdir -p lib/core/services

# data
mkdir -p lib/data/models
mkdir -p lib/data/providers

# modules/auth
mkdir -p lib/modules/auth/controllers
mkdir -p lib/modules/auth/views

# modules/customer
mkdir -p lib/modules/customer/home
mkdir -p lib/modules/customer/explore
mkdir -p lib/modules/customer/requests
mkdir -p lib/modules/customer/reviews
mkdir -p lib/modules/customer/favorites
mkdir -p lib/modules/customer/wallet
mkdir -p lib/modules/customer/profile
mkdir -p lib/modules/customer/notifications
mkdir -p lib/modules/customer/marketing
mkdir -p lib/modules/customer/controllers
mkdir -p lib/modules/customer/views

# modules/artisan
mkdir -p lib/modules/artisan/home
mkdir -p lib/modules/artisan/requests
mkdir -p lib/modules/artisan/earnings
mkdir -p lib/modules/artisan/wallet
mkdir -p lib/modules/artisan/portfolio
mkdir -p lib/modules/artisan/services
mkdir -p lib/modules/artisan/profile
mkdir -p lib/modules/artisan/notifications
mkdir -p lib/modules/artisan/controllers
mkdir -p lib/modules/artisan/views

# modules/chat
mkdir -p lib/modules/chat/controllers
mkdir -p lib/modules/chat/views

# widgets
mkdir -p lib/widgets/buttons
mkdir -p lib/widgets/inputs
mkdir -p lib/widgets/cards
mkdir -p lib/widgets/loaders

echo "✅ Structure created successfully."

