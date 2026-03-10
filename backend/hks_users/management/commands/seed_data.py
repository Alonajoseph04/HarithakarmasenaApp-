from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import date, timedelta
import random

class Command(BaseCommand):
    help = 'Seed the database with demo data for HKS Waste Management System'

    def handle(self, *args, **kwargs):
        from hks_users.models import HKSUser
        from hks_wards.models import Ward
        from hks_workers.models import Worker
        from hks_households.models import Household
        from hks_collections.models import Collection
        from hks_notifications.models import Notification

        self.stdout.write('[HKS] Seeding demo data...')

        # --- Admin ---
        admin, _ = HKSUser.objects.get_or_create(username='admin', defaults={
            'role': 'admin', 'first_name': 'HKS', 'last_name': 'Admin',
            'email': 'admin@hks.local', 'is_staff': True, 'is_superuser': True,
        })
        admin.set_password('admin@123')
        admin.save()
        self.stdout.write('  [OK] Admin: admin / admin@123')

        # --- Wards ---
        ward_names = ['Ward 1 - Manacaud', 'Ward 2 - Vettucaud', 'Ward 3 - Poonthura',
                      'Ward 4 - Vizhinjam', 'Ward 5 - Kovalam']
        wards = []
        for i, name in enumerate(ward_names):
            w, _ = Ward.objects.get_or_create(name=name, defaults={'total_houses': 30 + i * 5, 'description': f'Coastal area {name}'})
            wards.append(w)
        self.stdout.write(f'  [OK] {len(wards)} Wards created')

        # --- Workers ---
        workers_data = [
            ('W001', 'Rajan', 'Kumar', '9876500001', wards[0]),
            ('W002', 'Suresh', 'Pillai', '9876500002', wards[1]),
            ('W003', 'Anitha', 'Nair', '9876500003', wards[2]),
        ]
        workers = []
        for wid, fn, ln, ph, ward in workers_data:
            user, _ = HKSUser.objects.get_or_create(username=wid, defaults={
                'role': 'worker', 'first_name': fn, 'last_name': ln, 'phone': ph
            })
            user.set_password('worker@123')
            user.save()
            worker, _ = Worker.objects.get_or_create(user=user, defaults={'worker_id': wid, 'ward': ward})
            if worker.ward != ward:
                worker.ward = ward
                worker.save()
            workers.append(worker)
        self.stdout.write(f'  [OK] {len(workers)} Workers: W001/worker@123, W002/worker@123, W003/worker@123')

        # --- Households ---
        household_data = [
            ('Krishnan Nair', 'Plot 12, Sea View Rd, Manacaud', '9876543210', wards[0], 150.0),
            ('Meena Lekshmi', 'TC 45/123, Vettucaud Lane', '9876543211', wards[0], 100.0),
            ('George Thomas', '23 Harbour View, Vettucaud', '9876543212', wards[1], 120.0),
            ('Thankamma Joseph', 'Flat 4B, Poonthura Complex', '9876543213', wards[1], 100.0),
            ('Abdul Rahiman', 'House 7, Fish Market St, Poonthura', '9876543214', wards[2], 100.0),
            ('Sreelekha Varma', 'Villa 3, Vizhinjam Hts', '9876543215', wards[2], 200.0),
            ('Biju Mathew', '15 Kovalam Beach Rd', '9876543216', wards[3], 150.0),
            ('Santha Kumari', 'TC 12/44, Kovalam West', '9876543217', wards[3], 100.0),
            ('Rameshan P', 'Old Lighthouse Rd, Kovalam', '9876543218', wards[4], 100.0),
            ('Lissy Kuriakose', 'WPC Colony, Manacaud', '9876543219', wards[0], 130.0),
            ('Babu Antony', 'Near Church, Vettucaud', '9876543220', wards[1], 100.0),
            ('Girija Menon', 'Hill View Apts, Vizhinjam', '9876543221', wards[3], 110.0),
            ('Shyamala Devi', 'Plot 88, Poonthura North', '9876543222', wards[2], 100.0),
            ('Xavier Fernandez', 'Sea Breeze, Kovalam', '9876543223', wards[4], 180.0),
            ('Pushpa Lakshmi', 'Old Town, Ward 1', '9876543224', wards[0], 100.0),
        ]
        households = []
        for name, addr, phone, ward, fee in household_data:
            user, _ = HKSUser.objects.get_or_create(phone=phone, defaults={
                'username': phone, 'role': 'household', 'first_name': name.split()[0],
                'last_name': ' '.join(name.split()[1:])
            })
            h, _ = Household.objects.get_or_create(phone=phone, defaults={
                'user': user, 'name': name, 'address': addr,
                'ward': ward, 'monthly_fee': fee
            })
            households.append(h)
        self.stdout.write(f'  [OK] {len(households)} Households created')

        # --- Collections ---
        waste_types = ['plastic', 'ewaste', 'organic', 'mixed', 'paper', 'glass']
        payment_methods = ['cash', 'upi']
        Collection.objects.all().delete()
        today = date.today()
        for i in range(25):
            hh = random.choice(households)
            worker = next((w for w in workers if w.ward == hh.ward), workers[0])
            weight = round(random.uniform(0.5, 15.0), 2)
            rate = random.choice([5.0, 8.0, 10.0, 12.0, 15.0])
            coll_date = today - timedelta(days=random.randint(0, 90))
            pm = random.choice(payment_methods)
            c = Collection.objects.create(
                household=hh, worker=worker, date=coll_date,
                waste_type=random.choice(waste_types),
                weight=weight, rate=rate,
                amount=round(weight * rate, 2),
                cleanliness=random.randint(2, 5),
                payment_method=pm,
                payment_status=random.choice(['paid', 'paid', 'pending']),
            )
        self.stdout.write(f'  [OK] 25 sample Collections created')

        # --- Notifications ---
        for h in households[:5]:
            if h.user:
                Notification.objects.get_or_create(
                    recipient=h.user,
                    title='Welcome to HKS! 🌿',
                    defaults={
                        'message': f'Hello {h.name}, your household is now registered with Haritha Karma Sena. Thank you for helping keep our ward clean!',
                        'notification_type': 'general'
                    }
                )

        self.stdout.write(self.style.SUCCESS('\n[DONE] Database seeded successfully!'))
        self.stdout.write('-----------------------------------')
        self.stdout.write('Admin     -> admin / admin@123')
        self.stdout.write('Workers   -> W001, W002, W003 / worker@123')
        self.stdout.write('Household -> Phone login with OTP (check API response for demo OTP)')
        self.stdout.write('-----------------------------------')
