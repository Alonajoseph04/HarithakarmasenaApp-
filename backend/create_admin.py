#!/usr/bin/env python
"""
Standalone script to create a default admin user if none exists.
Run automatically on Railway startup AFTER django.setup() is called.
"""
import os
import django

# MUST set settings module before calling setup()
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hks_backend.settings')

# MUST call django.setup() before importing any models
django.setup()

# Only import after setup()
from django.contrib.auth import get_user_model  # noqa: E402

User = get_user_model()

username = os.environ.get('ADMIN_USERNAME', 'admin')
password = os.environ.get('ADMIN_PASSWORD', 'hks@admin123')
email    = os.environ.get('ADMIN_EMAIL', 'admin@hks.com')

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, password=password, email=email)
    print(f"✓ Admin user '{username}' created successfully.")
else:
    print(f"✓ Admin user '{username}' already exists.")
