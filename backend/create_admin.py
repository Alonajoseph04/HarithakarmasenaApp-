#!/usr/bin/env python
"""
Standalone script to create a default admin user if none exists.
Run automatically on Railway startup AFTER migrations are applied.
Ensures role='admin' is always set correctly.
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

user = User.objects.filter(username=username).first()

if user is None:
    # Create brand new superuser with role=admin
    user = User.objects.create_superuser(
        username=username,
        password=password,
        email=email,
        role='admin',
    )
    print(f"✓ Admin user '{username}' created with role=admin.")
else:
    # User exists — ensure role is set to admin
    changed = False
    if user.role != 'admin':
        user.role = 'admin'
        changed = True
    if not user.is_staff:
        user.is_staff = True
        changed = True
    if not user.is_superuser:
        user.is_superuser = True
        changed = True
    if changed:
        user.save()
        print(f"✓ Admin user '{username}' updated: role set to admin.")
    else:
        print(f"✓ Admin user '{username}' already exists with correct role.")
