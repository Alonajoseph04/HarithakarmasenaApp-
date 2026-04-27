#!/usr/bin/env python
"""
Management command to create a default admin user if none exists.
Run automatically on Railway startup.
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hks_backend.settings')

from django.contrib.auth import get_user_model

User = get_user_model()

username = os.environ.get('ADMIN_USERNAME', 'admin')
password = os.environ.get('ADMIN_PASSWORD', 'hks@admin123')
email = os.environ.get('ADMIN_EMAIL', 'admin@hks.com')

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, password=password, email=email)
    print(f"✓ Admin user '{username}' created successfully.")
else:
    print(f"✓ Admin user '{username}' already exists.")
