import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model

User = get_user_model()
logger = logging.getLogger(__name__)


class BaseConsumer(AsyncWebsocketConsumer):
    """Base WebSocket consumer with authentication."""

    async def connect(self):
        # Get user from scope (set by auth middleware)
        self.user = self.scope.get("user")
        if not self.user or not self.user.is_authenticated:
            await self.close(code=4001)
            return

        self.room_group_name = None
        await self.accept()

    async def disconnect(self, close_code):
        if self.room_group_name:
            await self.channel_layer.group_discard(
                self.room_group_name, self.channel_name
            )

    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            message_type = data.get("type")
            handler = getattr(self, f"handle_{message_type}", None)
            if handler:
                await handler(data)
            else:
                await self.send_error(f"Unknown message type: {message_type}")
        except json.JSONDecodeError:
            await self.send_error("Invalid JSON")
        except Exception as e:
            logger.exception("WebSocket error")
            await self.send_error(str(e))

    async def send_error(self, message):
        await self.send(text_data=json.dumps({"type": "error", "message": message}))

    async def send_message(self, event):
        """Send message to WebSocket."""
        await self.send(text_data=json.dumps(event["message"]))

    @database_sync_to_async
    def get_user(self, user_id):
        try:
            return User.objects.get(id=user_id)
        except User.DoesNotExist:
            return None


class NotificationConsumer(BaseConsumer):
    """Real-time notifications."""

    async def connect(self):
        await super().connect()
        if self.user:
            self.room_group_name = f"notifications_{self.user.id}"
            await self.channel_layer.group_add(self.room_group_name, self.channel_name)

    async def handle_ping(self, data):
        await self.send(text_data=json.dumps({"type": "pong"}))

    async def notification_message(self, event):
        """Send notification to WebSocket."""
        await self.send(text_data=json.dumps(event["message"]))


class OrderTrackingConsumer(BaseConsumer):
    """Real-time order status updates."""

    async def connect(self):
        await super().connect()
        if self.user:
            # User can subscribe to multiple order rooms
            self.order_rooms = set()
            self.room_group_name = f"orders_{self.user.id}"
            await self.channel_layer.group_add(self.room_group_name, self.channel_name)

    async def handle_subscribe_order(self, data):
        """Subscribe to specific order updates (owner, assigned agent, tenant
        member, or staff only — otherwise any ID would leak status/note data)."""
        order_id = data.get("order_id")
        if not order_id:
            return
        if not await self.can_access_order(order_id):
            await self.send_error("Not authorized for this order")
            return
        room_name = f"order_{order_id}"
        self.order_rooms.add(room_name)
        await self.channel_layer.group_add(room_name, self.channel_name)
        await self.send(text_data=json.dumps({
            "type": "subscribed",
            "order_id": order_id,
        }))

    @database_sync_to_async
    def can_access_order(self, order_id):
        from django.core.exceptions import ValidationError

        from orders.models import Order
        from tenants.services import user_tenant_ids

        try:
            order = Order.objects.select_related("store").get(pk=order_id)
        except (Order.DoesNotExist, ValueError, ValidationError):
            return False
        if self.user.is_staff or order.user_id == self.user.id:
            return True
        tenant_id = order.tenant_id or (
            order.store.tenant_id if order.store_id else None
        )
        if tenant_id and tenant_id in user_tenant_ids(self.user):
            return True
        from delivery.models import DeliveryAssignment

        return DeliveryAssignment.objects.filter(
            order=order, agent=self.user
        ).exists()

    async def handle_unsubscribe_order(self, data):
        order_id = data.get("order_id")
        if order_id:
            room_name = f"order_{order_id}"
            self.order_rooms.discard(room_name)
            await self.channel_layer.group_discard(room_name, self.channel_name)

    async def order_update(self, event):
        """Send order status update."""
        await self.send(text_data=json.dumps(event["message"]))


class InventoryConsumer(BaseConsumer):
    """Real-time inventory updates for merchants."""

    async def connect(self):
        await super().connect()
        if self.user and (self.user.is_staff or self.user.role == self.user.Role.STORE_MANAGER):
            self.room_group_name = f"inventory_{self.user.id}"
            await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        else:
            await self.close(code=4003)

    async def inventory_update(self, event):
        """Send inventory change notification."""
        await self.send(text_data=json.dumps(event["message"]))


class ChatConsumer(BaseConsumer):
    """Real-time chat for support/order discussions."""

    async def connect(self):
        await super().connect()
        if self.user:
            self.room_group_name = f"chat_{self.user.id}"
            await self.channel_layer.group_add(self.room_group_name, self.channel_name)

    async def handle_join_room(self, data):
        room_id = data.get("room_id")
        if not room_id:
            return
        if not await self.check_room_access(room_id):
            await self.send_error("Not authorized for this room")
            return
        self.current_room = room_id
        await self.channel_layer.group_add(f"chat_room_{room_id}", self.channel_name)
        await self.send(text_data=json.dumps({
            "type": "joined_room",
            "room_id": room_id,
        }))

    async def handle_send_message(self, data):
        room_id = data.get("room_id")
        content = data.get("content")
        message_type = data.get("message_type", "TEXT")

        if not room_id or not content:
            await self.send_error("room_id and content required")
            return

        # Verify user is participant
        has_access = await self.check_room_access(room_id)
        if not has_access:
            await self.send_error("Not authorized for this room")
            return

        # Save message
        message = await self.save_message(room_id, content)
        if message:
            # Broadcast to room
            await self.channel_layer.group_send(
                f"chat_room_{room_id}",
                {
                    "type": "chat_message",
                    "message": {
                        "type": "new_message",
                        "message": {
                            "id": str(message.id),
                            "room_id": room_id,
                            "sender": message.sender.email,
                            "content": message.content,
                            "message_type": message.message_type,
                            "created_at": message.created_at.isoformat(),
                        },
                    },
                },
            )

    async def handle_typing(self, data):
        room_id = data.get("room_id")
        is_typing = data.get("is_typing", False)
        if not room_id:
            return
        if not await self.check_room_access(room_id):
            await self.send_error("Not authorized for this room")
            return
        await self.channel_layer.group_send(
            f"chat_room_{room_id}",
            {
                "type": "user_typing",
                "message": {
                    "type": "typing",
                    "user": self.user.email,
                    "room_id": room_id,
                    "is_typing": is_typing,
                },
            },
        )

    @database_sync_to_async
    def check_room_access(self, room_id):
        from .models import ChatRoom
        try:
            room = ChatRoom.objects.get(id=room_id)
            return room.participants.filter(id=self.user.id).exists()
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, room_id, content):
        from .models import ChatMessage, ChatRoom
        try:
            room = ChatRoom.objects.get(id=room_id)
            return ChatMessage.objects.create(
                room=room,
                sender=self.user,
                content=content,
            )
        except ChatRoom.DoesNotExist:
            return None

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event["message"]))

    async def user_typing(self, event):
        await self.send(text_data=json.dumps(event["message"]))