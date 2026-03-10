from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Notification
from .serializers import NotificationSerializer, NotificationCreateSerializer
from hks_users.models import HKSUser

class NotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filterset_fields = ['notification_type', 'is_read']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return Notification.objects.all()
        return Notification.objects.filter(recipient=user)

    def get_serializer_class(self):
        if self.action == 'create':
            return NotificationCreateSerializer
        return NotificationSerializer

    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save()
        return Response({'message': 'Marked as read'})

    @action(detail=False, methods=['patch'])
    def mark_all_read(self, request):
        self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({'message': 'All notifications marked as read'})

    @action(detail=False, methods=['post'])
    def broadcast(self, request):
        if request.user.role != 'admin':
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        title = request.data.get('title', 'Admin Announcement')
        message = request.data.get('message', '')
        target = request.data.get('target', 'all')  # all, workers, households

        if target == 'all':
            recipients = HKSUser.objects.exclude(role='admin')
        elif target == 'workers':
            recipients = HKSUser.objects.filter(role='worker')
        elif target == 'households':
            recipients = HKSUser.objects.filter(role='household')
        else:
            recipients = HKSUser.objects.none()

        notifications = [
            Notification(recipient=u, title=title, message=message, notification_type='broadcast')
            for u in recipients
        ]
        Notification.objects.bulk_create(notifications)
        return Response({'message': f'Broadcast sent to {len(notifications)} users'})

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        count = self.get_queryset().filter(is_read=False).count()
        return Response({'unread_count': count})
